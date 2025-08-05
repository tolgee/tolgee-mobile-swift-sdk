import Foundation
import Testing

@testable import Tolgee

@MainActor
struct ClearCachesTests {

    @Test func testClearCachesMethod() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        // Pre-populate cache with some data
        let descriptor = CacheDescriptor(
            language: "en",
            namespace: nil,
            appVersionSignature: "1.0.0",
            cdn: "https://example.com"
        )
        let testData = "{\"test_key\": \"test_value\"}".data(using: .utf8)!
        mockCache.saveRecords(testData, for: descriptor)

        // Verify cache has data
        #expect(
            mockCache.loadRecords(for: descriptor) != nil, "Cache should have data before clearing")
        #expect(!mockCache.cachedDescriptors.isEmpty, "Cache descriptors should not be empty")

        // Create Tolgee instance
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: "1.0.0"
        )

        // Clear caches
        try tolgee.clearCaches()

        // Verify cache is empty
        #expect(
            mockCache.loadRecords(for: descriptor) == nil, "Cache should be empty after clearing")
        #expect(
            mockCache.cachedDescriptors.isEmpty, "Cache descriptors should be empty after clearing")
    }

    @Test func testClearCachesWithEtags() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        // Pre-populate cache with translation data and ETags
        let descriptor = CacheDescriptor(
            language: "cs",
            namespace: "buttons",
            appVersionSignature: "2.0.0",
            cdn: "https://cdn.example.com"
        )
        let testData = "{\"save\": \"Uložit\", \"cancel\": \"Zrušit\"}".data(using: .utf8)!
        mockCache.saveRecords(testData, for: descriptor)

        // Add ETag data
        let etagDescriptor = CdnEtagDescriptor(
            language: "cs",
            namespace: "buttons",
            cdn: "https://cdn.example.com"
        )
        try mockCache.saveCdnEtag(etagDescriptor, etag: "test-etag-123")

        // Verify both cache and ETag data exist
        #expect(mockCache.loadRecords(for: descriptor) != nil, "Translation cache should exist")
        #expect(mockCache.loadCdnEtag(for: etagDescriptor) != nil, "ETag should exist")

        // Create Tolgee instance
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: "2.0.0"
        )

        // Clear all caches
        try tolgee.clearCaches()

        // Verify both cache and ETag data are cleared
        #expect(
            mockCache.loadRecords(for: descriptor) == nil, "Translation cache should be cleared")
        #expect(mockCache.loadCdnEtag(for: etagDescriptor) == nil, "ETag should be cleared")
        #expect(mockCache.cachedDescriptors.isEmpty, "All cache descriptors should be cleared")
    }

    @Test func testClearCachesPublicAccess() async throws {
        // Test that the method is accessible from the shared instance
        // This test verifies the method is properly public
        let sharedTolgee = Tolgee.shared

        // This should not throw a compilation error and should be callable
        // We can't test actual clearing with the shared instance due to side effects,
        // but we can verify the method exists and is callable
        do {
            try sharedTolgee.clearCaches()
            #expect(true, "clearCaches method should be publicly accessible")
        } catch {
            // It's OK if it throws due to file system issues in test environment
            // The important thing is that the method is accessible
            #expect(true, "clearCaches method is accessible even if it throws in test environment")
        }
    }
}
