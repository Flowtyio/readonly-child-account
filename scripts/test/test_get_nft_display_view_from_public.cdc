import "NonFungibleToken"
import "MetadataViews"
import "HybridCustody"

/* 
 * TEST SCRIPT
 * This script is a replication of that found in hybrid-custody/get_nft_display_view_from_public as it's the best as
 * as can be done without accessing the script's return type in the Cadence testing framework
 */

/// Assertion method to ensure passing test
///
pub fun assertPassing(result: {Address: {UInt64: MetadataViews.Display}}, expectedAddressToIDs: {Address: [UInt64]}) {

    for address in result.keys {
        if expectedAddressToIDs[address] == nil {
            panic("Address ".concat(address.toString()).concat(" found but not expected!"))
        }
        let expectedIDs: [UInt64] = expectedAddressToIDs[address]!
        for i, id in result[address]!.keys {
            if expectedIDs[i] != id {
                panic("Resulting ID does not match expected ID!")
            }
        }
    }
}

/// Returns resolved Display from given address at specified path for each ID or nil if ResolverCollection is not found
///
pub fun getViews(_ address: Address, _ resolverCollectionPath: PublicPath): {UInt64: MetadataViews.Display} {
    
    let account: PublicAccount = getAccount(address)
    let views: {UInt64: MetadataViews.Display} = {}

    // Borrow the Collection
    if let collection = account
        .getCapability<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(resolverCollectionPath).borrow() {
        // Iterate over IDs & resolve the view
        for id in collection.getIDs() {
            let display = collection.borrowViewResolver(id: id).resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display
            views.insert(key: id, display)
        }
    }

    return views
}

/// Queries for MetadataViews.Display each NFT across all associated accounts from Collections at the provided
/// PublicPath
///
// pub fun main(address: Address, resolverCollectionPath: PublicPath): {Address: {UInt64: MetadataViews.Display}} {
pub fun main(address: Address, resolverCollectionPath: PublicPath, expectedAddressToIDs: {Address: [UInt64]}) {

    let allViews: {Address: {UInt64: MetadataViews.Display}} = {address: getViews(address, resolverCollectionPath)}
    let seen: [Address] = [address]
    
    /* Iterate over any associated accounts */ 
    //
    if let managerRef = getAuthAccount(address).borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) {
        
        for childAccount in managerRef.getChildAddresses() {
            allViews.insert(key: childAccount, getViews(address, resolverCollectionPath))
            seen.append(childAccount)
        }

        for ownedAccount in managerRef.getOwnedAddresses() {
            if seen.contains(ownedAccount) == false {
                allViews.insert(key: ownedAccount, getViews(address, resolverCollectionPath))
                seen.append(ownedAccount)
            }
        }
    }
    // Assert instead of return for testing purposes here
    assertPassing(result: allViews, expectedAddressToIDs: expectedAddressToIDs)
    // return allViews 
}
 