#ifndef _TYPE_DMAMAP_
#define _TYPE_DMAMAP_
include "dmapattr.td"

def dmapcoreenginegrouptype:dmaptype<"dmacoreenginegroup"> {
    let mnemonic = "core engine group";
    let summary = "this is dmap process engine group";
}

def dmapioenginetype:dmaptype<"dmapioenginetype"> {
    let mnemonic = " io engine";
    let summary = "this is dmap IO engine";
}

def dmapporttype : dmaptype<"dmapport"> {
    let mnemonic = "dmapport";
    let summary = "this is a dmap port";
}

def dmapportgrouptype : dmaptype<"dmapportgroup"> {
    let mnemonic = "dmapportgroup";
    let summary = "this is a dmap port";
}

def dmapportstreamtype : dmaptype<"dmapportstreamtype"> {
    let mnemonic = "dmapportstreamtype";
    let summary = "this is a dmap stream port";
}

def dmapdatatype : dmaptype<"dmapdata"> {
    let mnemonic = "dmapdata";
    let summary = "this is a dmap data";
}

def dmapportorgroup : TypeConstraint<
  CPred<"$_self.isa<dflow::PortType>() || $_self.isa<dflow::PortGroupType>()">,
  "port or port group">;

#endif //_TYPE_DMAMAP_