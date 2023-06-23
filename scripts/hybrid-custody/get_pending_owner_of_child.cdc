import "HybridCustody"

pub fun main(addr: Address): Address? {
    let acct = getAuthAccount(addr)
    let c = acct.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.ChildStoragePath)
        ?? panic("owned account missing")
    
    return c.getPendingOwner()
}