#ifndef _TYPE_DMAMAP_
#define _TYPE_DMAMAP_
include "dmapattr.td"
def dmapporttype : dmaptype<"dmapport"> {
    let mnemonic = "dmapport";
    let summary = "this is a dmap port";
}

#endif //_TYPE_DMAMAP_