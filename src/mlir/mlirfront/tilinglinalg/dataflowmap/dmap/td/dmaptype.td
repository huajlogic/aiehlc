#ifndef _TYPE_DMAMAP_
#define _TYPE_DMAMAP_
include "dmapattr.td"
def dmapiotype : dmaptype<"dmapio"> {
    let mnemonic = "dmapio";
    let summary = "this is a dmap io";
}

#endif //_TYPE_DMAMAP_