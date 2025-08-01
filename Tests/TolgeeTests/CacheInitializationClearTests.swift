import Foundation
import Testing

@testable import Tolgee

@MainActor
struct CacheInitializationClearTests {

    @Test func testClearCacheWhenNoCacheFound() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()
        let mockLifecycleObserver = MockLifecycleObserver()

        // Pre-populate cache with data for a different app version to simulate old cache
        let oldVersionDescriptor = CacheDescriptor(
            language: "en",
            namespace: nil,
            appVersionSignature: "old-1.0.0"
        )
        let oldCacheData = "{\"old_key\": \"old value\"}".data(using: .utf8)!
        mockCache.saveRecords(oldCacheData, for: oldVersionDescriptor)

        // Verify old cache exists
        #expect(
            mockCache.loadRecords(for: oldVersionDescriptor) != nil,
            "Old cache should exist before initialization")

        // Create Tolgee instance with different app version
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            lifecycleObserver: mockLifecycleObserver,
            appVersionSignature: "new-2.0.0"
        )

        // Initialize - since no cache exists for the new version, it should clear all cache
        tolgee.initialize(language: "en")

        // Verify old cache was cleared
        #expect(
            mockCache.loadRecords(for: oldVersionDescriptor) == nil,
            "Old cache should be cleared after initialization")
        #expect(mockCache.cachedDescriptors.isEmpty, "All cache should be cleared")
    }

    @Test func testDoNotClearCacheWhenCacheFound() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()
        let mockLifecycleObserver = MockLifecycleObserver()

        let appVersionSignature = "current-1.5.0"

        // Pre-populate cache with data for the current app version
        let currentVersionDescriptor = CacheDescriptor(
            language: "en",
            namespace: nil,
            appVersionSignature: appVersionSignature
        )
        let currentCacheData = "{\"current_key\": \"current value\"}".data(using: .utf8)!
        mockCache.saveRecords(currentCacheData, for: currentVersionDescriptor)

        // Also add some old cache data
        let oldVersionDescriptor = CacheDescriptor(
            language: "en",
            namespace: nil,
            appVersionSignature: "old-1.0.0"
        )
        let oldCacheData = "{\"old_key\": \"old value\"}".data(using: .utf8)!
        mockCache.saveRecords(oldCacheData, for: oldVersionDescriptor)

        // Verify both caches exist
        #expect(
            mockCache.loadRecords(for: currentVersionDescriptor) != nil,
            "Current cache should exist")
        #expect(mockCache.loadRecords(for: oldVersionDescriptor) != nil, "Old cache should exist")

        // Create Tolgee instance with the current app version
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            lifecycleObserver: mockLifecycleObserver,
            appVersionSignature: appVersionSignature
        )

        // Initialize - since cache exists for the current version, it should NOT clear cache
        tolgee.initialize(language: "en")

        // Verify both caches still exist (no clearing happened)
        #expect(
            mockCache.loadRecords(for: currentVersionDescriptor) != nil,
            "Current cache should still exist")
        #expect(
            mockCache.loadRecords(for: oldVersionDescriptor) != nil, "Old cache should still exist")
        #expect(!mockCache.cachedDescriptors.isEmpty, "Cache should not be empty")
    }

    @Test func testClearCacheWithNamespaces() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()
        let mockLifecycleObserver = MockLifecycleObserver()

        // Pre-populate cache with old data
        let oldDescriptors = [
            CacheDescriptor(language: "en", namespace: nil, appVersionSignature: "old-1.0.0"),
            CacheDescriptor(language: "en", namespace: "buttons", appVersionSignature: "old-1.0.0"),
            CacheDescriptor(language: "es", namespace: nil, appVersionSignature: "old-1.0.0"),
        ]

        let oldCacheData = "{\"old_key\": \"old value\"}".data(using: .utf8)!
        for descriptor in oldDescriptors {
            mockCache.saveRecords(oldCacheData, for: descriptor)
        }

        // Verify old cache exists
        for descriptor in oldDescriptors {
            #expect(mockCache.loadRecords(for: descriptor) != nil, "Old cache should exist")
        }

        // Create Tolgee instance with new app version and namespaces
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            lifecycleObserver: mockLifecycleObserver,
            appVersionSignature: "new-2.0.0"
        )

        // Initialize with namespaces - no cache exists for new version, should clear all
        tolgee.initialize(language: "en", namespaces: ["buttons", "messages"])

        // Verify all old cache was cleared
        for descriptor in oldDescriptors {
            #expect(mockCache.loadRecords(for: descriptor) == nil, "Old cache should be cleared")
        }
        #expect(mockCache.cachedDescriptors.isEmpty, "All cache should be cleared")
    }
}
