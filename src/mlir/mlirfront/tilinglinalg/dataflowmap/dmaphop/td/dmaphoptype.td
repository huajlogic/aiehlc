#ifndef _TYPE_DMAMAP_
#define _TYPE_DMAMAP_
include "dmaphopattr.td"

def dmapcoreenginegrouptype:dmaptype<"dmacoreenginegroup"> {
    let mnemonic = "dmacoreenginegroupType";
    let summary = "this is dmap process engine group";
}

//def dmapportorgroup : TypeConstraint<
// CPred<"$_self.isa<dflow::PortType>() || $_self.isa<dflow::PortGroupType>()">,
 // "port or port group">;

#endif //_TYPE_DMAMAP_