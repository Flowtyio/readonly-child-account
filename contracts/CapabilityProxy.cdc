/*
CapabilityProxy is a contract used to share Capabiltities to other
accounts. It is used by the RestrictedChildAccount contract to allow
more flexible sharing of Capabilities when an app wants to share things that
aren't the NFT-standard interface types.

Inside of CapabilityProxy is a resource called Proxy which 
maintains a mapping of public and private capabilities. They cannot and should
not be mixed. A public proxy is able to be borrowed by anyone, whereas a private proxy
can only be borrowed on the RestrictedChildAccount when you have access to the full
RestrictedAccount resource.
*/
pub contract CapabilityProxy {
    pub let StoragePath: StoragePath
    pub let PrivatePath: PrivatePath
    pub let PublicPath: PublicPath
    
    pub event ProxyCreated(id: UInt64)
    
    pub event CapabilityAdded(address: Address, type: Type, isPublic: Bool)
    pub event CapabilityRemoved(address: Address, type: Type)

    pub resource interface GetterPrivate {
        pub fun getPrivateCapability(_ type: Type): Capability? {
            post {
                result == nil || type.isSubtype(of: result.getType()): "incorrect returned capability type"
            }
        }

        pub fun findFirstPrivateType(_ type: Type): Type?
        pub fun getAllPrivate(): [Capability]
    }

    pub resource interface GetterPublic {
        pub fun getPublicCapability(_ type: Type): Capability? {
            post {
                result == nil || type.isSubtype(of: result.getType()): "incorrect returned capability type "
            }
        }

        pub fun findFirstPublicType(_ type: Type): Type?
        pub fun getAllPublic(): [Capability]
    }

    pub resource Proxy: GetterPublic, GetterPrivate {
        access(self) let privateCapabilities: {Type: Capability}
        access(self) let publicCapabilities: {Type: Capability}

        // ------ Begin Getter methods
        pub fun getPublicCapability(_ type: Type): Capability? {
            return self.publicCapabilities[type]
        }

        pub fun getPrivateCapability(_ type: Type): Capability? {
            return self.privateCapabilities[type]
        }

        pub fun getAllPublic(): [Capability] {
            return self.publicCapabilities.values
        }

        pub fun getAllPrivate(): [Capability] {
            return self.publicCapabilities.values
        }

        pub fun findFirstPublicType(_ type: Type): Type? {
            for t in self.publicCapabilities.keys {
                if t.isSubtype(of: type) {
                    return t
                }
            }

            return nil
        }

        pub fun findFirstPrivateType(_ type: Type): Type? {
            for t in self.privateCapabilities.keys {
                if t.isSubtype(of: type) {
                    return t
                }
            }

            return nil
        }
        // ------- End Getter methods

        pub fun addCapability(cap: Capability, isPublic: Bool) {
            assert(cap.borrow<&AnyResource>() != nil, message: "capability could not be borrowed")
            if isPublic {
                self.publicCapabilities[cap.getType()] = cap
            } else {
                self.privateCapabilities[cap.getType()] = cap
            }
        }

        pub fun removeCapability(cap: Capability) {
            self.publicCapabilities.remove(key: cap.getType())
            self.privateCapabilities.remove(key: cap.getType())
        }

        init() {
            self.privateCapabilities = {}
            self.publicCapabilities = {}
        }
    }

    pub fun createProxy(): @Proxy {
        return <- create Proxy()
    }
    
    init() {
        let identifier = "CapabilityProxy".concat(self.account.address.toString())
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PrivatePath = PrivatePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}
 