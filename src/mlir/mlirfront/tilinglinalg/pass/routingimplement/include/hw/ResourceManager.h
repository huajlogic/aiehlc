/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

//====================================================================
// routingresource.h
//====================================================================
#ifndef ROUTINGRESOURCE_H
#define ROUTINGRESOURCE_H

#include "hwresource.h"
#include <string>
#include <vector>
#include <unordered_map>
#include <optional>
#include <map>
#include <atomic>
#include <array>
#include <stdexcept>
#include <mutex>
inline PortDirection opposite(PortDirection d){
    return d==PortDirection::North ? PortDirection::South :
           d==PortDirection::South ? PortDirection::North :
           d==PortDirection::East  ? PortDirection::West  :
           d==PortDirection::West  ? PortDirection::East  : d;
}
inline PortDirection getDir(Point a, Point b){
    if(a.r==b.r-1 && b.c==a.c) return PortDirection::North;
    if(a.r==b.r+1 && b.c==a.c) return PortDirection::South;
    if(b.c==a.c-1 && b.r==a.r) return PortDirection::West;
    if(b.c==a.c+1 && b.r==a.r) return PortDirection::East;
    throw std::runtime_error("Points not neighbours");
}

/*
some port is enabled by hw design, in here it specify to SHIM tile input/output port
for example only port 3 and port 7 enabled by HW to responsible on data movement from
DDR
*/
struct PortSlot { bool used=false; bool invalid=false; int portNum=-1; int ioId=-1; };
struct DirBank  { std::vector<PortSlot> master; std::vector<PortSlot> slave; };
enum class IOType {Input, Output, TileDMA};
// Added for tile reservation
enum class ReservationStrategy {
    COLUMN_FIRST,
    ROW_FIRST
};
class RoutingTile {
public:
    RoutingTile(int r,int c, TileType tt,const std::vector<PortTemplate> & Portinfo);

    std::optional<int> allocate(IOType io, int portNum,PortDirection dir, int ioId);
    std::optional<int> occupyport(IOType io, PortDirection dir, int ioId);
    bool releaseByIo (IOType io, int portNum,PortDirection dir, int ioId);

    const DirBank& bank(PortDirection d) const { return banks_.at(d); }
    TileType type() const { return type_; }
    int row()   const { return row_; }
    int col()   const { return col_; }

    // Added for tile reservation
    bool isReserved() const { return reserved_; }
    void setReserved(bool reserved, int ioId) { 
        reserved_ = reserved; 
        if (reserved) {
            reservedByIoId_ = ioId;
        } else {
            reservedByIoId_ = -1;
        }
    }
    int getReservedByIoId() const { return reservedByIoId_; }

private:
    int row_, col_;
    TileType type_;
    std::unordered_map<PortDirection, DirBank> banks_;
    // Added for tile reservation
    bool reserved_ = false;
    int reservedByIoId_ = -1;
};

class ShimIOPort {
public:
    ShimIOPort(IOType iotype, PortDirection dir, int portnum): iotype_(iotype), dir_(dir), portnum_(portnum){};
    IOType iotype_;
    PortDirection dir_;
    int portnum_;
};

class DataIO {
public:
    DataIO(IOType tp, int r, int c, std::string nm="", std::string cmt = "");
    int                id()      const { return id_; }
    int                rowpos()    const { return rowpos_; }
    int                colpos()    const { return colpos_; }
    IOType             type()    const { return type_; }
    const std::string& name()    const { return name_; }
    const std::string& comment() const { return comment_; }

    // Added for tile reservation
    const std::vector<Point>& getReservedTiles() const { return reservedTiles_; }
    void addReservedTile(const Point& p) { reservedTiles_.push_back(p); }
    void clearReservedTiles() { reservedTiles_.clear(); }
    std::optional<ShimIOPort> getshimport() {return shimport_;};
    void setshimport(std::optional<ShimIOPort> shimport) {shimport_ = shimport;};
private:
    static std::atomic<int> next_;
    int          id_, rowpos_, colpos_;
    IOType       type_;
    std::string  name_, comment_;
    std::vector<Point> reservedTiles_;
    std::optional<ShimIOPort> shimport_;
};

class ResourceMgr {
public:
    ResourceMgr(std::unique_ptr<IHwResource> resource, TileType defaultType = TileType::Core);
    static bool     init(std::unique_ptr<IHwResource> resource, TileType defType = TileType::Core);
    static std::shared_ptr<ResourceMgr> instance();

    std::shared_ptr<DataIO> createDataIO(IOType tp, int r=0, int c=0, std::string nm="", std::string cmt="");
    bool linkAvailable(Point a, Point b, int& portNum) const;
    bool occupyLink(Point a, Point b, const int ioId,int& portNum, PortDirection& pda, PortDirection& pdb);
    bool releaseLink(Point a, Point b, int ioId,int portNum);
    std::optional<Point> freeShimNoc(std::optional<Point> dst = std::nullopt )const;
    RoutingTile&       tile(int r,int c);
    const RoutingTile& tile(int r,int c) const;
    int rows() const;
    int cols() const;
    static std::once_flag              flag_;
    static std::shared_ptr<ResourceMgr> singleton_;

    // methods for tile reservation
    bool isTileReserved(int r, int c) const;
    bool isTileReserved(const Point& p) const { return isTileReserved(p.r, p.c); }
    
    // Reserve a specified tile for a DataIO
    bool reserveTile(int r, int c, int ioId);
    bool reserveTile(const Point& p, int ioId) { return reserveTile(p.r, p.c, ioId); }
    
    // Reserve multiple tiles for a DataIO using a strategy
    bool reserveTiles(int ioId, int numTiles, ReservationStrategy strategy, 
                      std::vector<Point>& allocatedTiles,
                      std::optional<TileType> requestedType = TileType::Core,
                      std::optional<Point> startPoint = std::nullopt);
    
    // Release all tiles reserved for a specific DataIO
    void releaseReservedTiles(int ioId);
    
    // Get all tiles reserved by a specific DataIO
    std::vector<Point> getReservedTilesForDataIo(int ioId) const;
    IHwResource* getrsc() {return resource_.get();};

private:
    std::vector<std::vector<RoutingTile>> tiles_;
     
    std::unique_ptr<IHwResource> resource_;
    std::unordered_map<int, std::shared_ptr<DataIO>> DataIOMap;
};

#endif // ROUTINGRESOURCE_H
