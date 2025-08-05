import Foundation
import os

@testable import Tolgee

/// Mock cache implementation for testing
final class MockCache: CacheProtocol, Sendable {
    private let storage = OSAllocatedUnfairLock<[CacheDescriptor: Data]>(initialState: [:])
    private let etagStorage = OSAllocatedUnfairLock<[CdnEtagDescriptor: String]>(initialState: [:])

    func loadRecords(for descriptor: CacheDescriptor) -> Data? {
        return storage.withLock { $0[descriptor] }
    }

    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) {
        storage.withLock { $0[descriptor] = data }
    }

    func clearAll() throws {
        storage.withLock { $0.removeAll() }
        etagStorage.withLock { $0.removeAll() }
    }

    func loadCdnEtag(for descriptor: CdnEtagDescriptor) -> String? {
        return etagStorage.withLock { $0[descriptor] }
    }

    func saveCdnEtag(_ descriptor: CdnEtagDescriptor, etag: String) throws {
        etagStorage.withLock { $0[descriptor] = etag }
    }

    /// Helper method to pre-populate cache for testing
    func preload(_ data: Data, for descriptor: CacheDescriptor) {
        storage.withLock { $0[descriptor] = data }
    }

    /// Helper method to clear all cached data
    func clear() {
        storage.withLock { $0.removeAll() }
        etagStorage.withLock { $0.removeAll() }
    }

    /// Helper method to pre-populate etag for testing
    func preloadEtag(_ etag: String, for descriptor: CdnEtagDescriptor) {
        etagStorage.withLock { $0[descriptor] = etag }
    }

    /// Helper method to check if cache contains data for descriptor
    func contains(_ descriptor: CacheDescriptor) -> Bool {
        return storage.withLock { $0[descriptor] != nil }
    }

    /// Helper method to check if cache contains etag for descriptor
    func containsEtag(for descriptor: CdnEtagDescriptor) -> Bool {
        return etagStorage.withLock { $0[descriptor] != nil }
    }

    /// Helper method to get all cached descriptors
    var cachedDescriptors: [CacheDescriptor] {
        return storage.withLock { Array($0.keys) }
    }
}
