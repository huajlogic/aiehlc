/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

//--------------------------------------------------------------------
// routing_path.cpp — Incremental tree router (col→row sorting)
//--------------------------------------------------------------------
#include "routing/routingpath.h"

#include <queue>
#include <limits>
#include <algorithm>
#include <unordered_set>
#include <iostream>
#include <cmath>
#include <iomanip>


const std::array<Point,4> kDirs{{ {-1,0},{1,0},{0,-1},{0,1} }}; // up,down,left,right

//--------------------------------------------------------------------
// ctor
//--------------------------------------------------------------------
RoutingPath::RoutingPath(std::shared_ptr<ResourceMgr> resmgr,std::shared_ptr<DataIO> dio, const std::vector<Point>& initObs)
    : R_(resmgr->rows()), C_(resmgr->cols()),
      wall_(R_,std::vector<bool>(C_,false)),
      tree_(R_,std::vector<bool>(C_,false)),
      parent_(R_,std::vector<Point>(C_,{-1,-1}))
{
    addObstacles(initObs);
    resmgr_= resmgr;
    dio_ = dio;
}

//--------------------------------------------------------------------
bool RoutingPath::inGrid(const Point& p) const {
    return p.r>=0 && p.r<R_ && p.c>=0 && p.c<C_;
}

void RoutingPath::addObstacles(const std::vector<Point>& obs){
    for(auto p:obs) if(inGrid(p)) wall_[p.r][p.c]=true;
}
void RoutingPath::addObstacle(const Point& p){ if(inGrid(p)) wall_[p.r][p.c]=true; }

void RoutingPath::markSeg(const std::vector<Point>& seg){
    for(auto p:seg) tree_[p.r][p.c]=true;
}

//--------------------------------------------------------------------
// find nearest existing tree point to dst (Manhattan)
//--------------------------------------------------------------------
Point RoutingPath::nearestTreePoint(const Point& dst) const {
    int best=std::numeric_limits<int>::max();
    Point cand{dst.r,dst.c};
    for(const auto& seg:paths_){
        for(auto p:seg){
            int d=std::abs(p.r-dst.r)+std::abs(p.c-dst.c);
            if(d<best){best=d;cand=p;}
        }
    }
    return cand;
}

bool RoutingPath::connectAvailable(Point start, Point goal) {
    int portNum;
    if (isWall(start.r,start.c)||isWall(goal.r,goal.c)) return false;
    return resmgr_->linkAvailable(start, goal, portNum);
}

//--------------------------------------------------------------------
// BFS (allows traversing existing tree_, but not walls)
//--------------------------------------------------------------------
bool RoutingPath::bfsSingle(const Point& start,const Point& goal,
                            std::vector<Point>& out){
    const int INF=std::numeric_limits<int>::max();
    std::vector<std::vector<int>> dist(R_,std::vector<int>(C_,INF));
    std::queue<Point> q;

    if(!inGrid(start)||!inGrid(goal)||isWall(start.r,start.c)||isWall(goal.r,goal.c))
        return false;
    dist[start.r][start.c]=0;
    parent_[start.r][start.c]={-1,-1};
    q.push(start);

    while(!q.empty()){
        Point cur=q.front();q.pop();
        if(cur==goal) break;
        for(auto d:kDirs){
            if(cur.r==0 && d.c!=0) continue; // row‑0 rule
            Point nxt{cur.r+d.r,cur.c+d.c};
            //check whether the connection have enough resource.
            if(!inGrid(nxt)||!connectAvailable(Point{cur.r, cur.c}, Point{nxt.r,nxt.c})) continue;
            if(dist[nxt.r][nxt.c]!=INF) continue;
            // allow stepping on tree_ tiles too
            dist[nxt.r][nxt.c]=dist[cur.r][cur.c]+1;
            parent_[nxt.r][nxt.c]=cur;
            q.push(nxt);
        }
    }
    if(dist[goal.r][goal.c]==INF) return false;
    // rebuild
    for(Point p=goal;p!=start;p=parent_[p.r][p.c]) out.push_back(p);
    out.push_back(start);
    std::reverse(out.begin(),out.end());
    return true;
}

//--------------------------------------------------------------------
// single sink public
//--------------------------------------------------------------------
bool RoutingPath::addPath(Point src,const Point& dst){
    std::vector<Point> seg;
    if(!bfsSingle(src,dst,seg)) return false;
    markSeg(seg);
    paths_.push_back(seg);
    return true;
}

bool RoutingPath::addIOTree(const std::vector<Point>& sinksIn) {
    return addIOTree(sinksIn, mutipaths_);
}
//--------------------------------------------------------------------
// multi sink incremental tree
//--------------------------------------------------------------------
bool RoutingPath::addIOTree(const std::vector<Point>& sinksIn,MultiPath& out){

    if (!dio_) return false;
    Point src = {dio_->rowpos(), dio_->colpos()};
    if(sinksIn.empty()) return false;
    // 1. sort sinks by col then row
    std::vector<Point> sinks=sinksIn;
    std::sort(sinks.begin(),sinks.end(),[](Point a,Point b){
        if(a.c!=b.c) return a.c<b.c;
        return a.r<b.r;
    });

    // 2. route to first sink
    std::vector<Point> seg;
    if(!bfsSingle(src,sinks[0],seg)) return false;
    markSeg(seg);
    paths_.push_back(seg);

    // 3. incremental for rest
    for(size_t i=1;i<sinks.size();++i){
        Point attach=nearestTreePoint(sinks[i]);
        seg.clear();
        if(!bfsSingle(attach,sinks[i],seg)) return false;
        // avoid duplicating first node if it already tree
        // mark new nodes only
        //for(auto p:seg){ if(!tree_[p.r][p.c]) paths_.back().push_back(p); }
        markSeg(seg);
        paths_.push_back(seg);
    }

    // fill MultiPath
    out.src=src;
    out.dsts=sinks;
    out.branches=paths_; // each entry in paths_ is a branch in this simple impl
    out.dataio = dio_;
    return true;
}

//--------------------------------------------------------------------
// Add this method to your RoutingPath class
void RoutingPath::dumpGrid() const {
    for(int r=R_-1;r>=0;--r){
        std::cout << std::setw(2) << r << " | ";  // Row number
        for(int c=0;c<C_;++c){
            std::string ch=".";
            if(wall_[r][c]) ch="X";
            else if(tree_[r][c]) {
                if (resmgr_->isTileReserved(r, c)) {
                    ch="*";//first print reserve
                }
                else ch="#";
            }
            //align
            int count = ((c == 0)?1:c);
            std::cout<<ch;
            while(count) {
                std::cout << " ";
                count = count/10;
            }
        }
        std::cout<<"\n";
    }

    // Print bottom border
    std::cout << "   +";
    for (int c = 0; c < C_; ++c){
        int count = ((c == 0)?1:c);
        std::cout << "-";
        while(count) {
            std::cout << "-";
            count = count/10;
        }
    }
    std::cout << "\n";

    // Print column numbers below
    std::cout << "     ";  // Align with row labels
    for (int c = 0; c < C_; ++c)
        std::cout << c << " ";
    std::cout << "\n\n";
}

