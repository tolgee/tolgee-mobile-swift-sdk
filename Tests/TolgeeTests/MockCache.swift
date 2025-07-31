import Foundation

@testable import Tolgee

/// Mock cache implementation for testing
actor MockCache: CacheProcotol {
    private var storage: [CacheDescriptor: Data] = [:]

    func loadRecords(for descriptor: CacheDescriptor) -> Data? {
        return storage[descriptor]
    }

    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) {
        storage[descriptor] = data
    }

    /// Helper method to pre-populate cache for testing
    func preload(_ data: Data, for descriptor: CacheDescriptor) {
        storage[descriptor] = data
    }

    /// Helper method to clear all cached data
    func clear() {
        storage.removeAll()
    }

    /// Helper method to check if cache contains data for descriptor
    func contains(_ descriptor: CacheDescriptor) -> Bool {
        return storage[descriptor] != nil
    }

    /// Helper method to get all cached descriptors
    var cachedDescriptors: [CacheDescriptor] {
        return Array(storage.keys)
    }
}
