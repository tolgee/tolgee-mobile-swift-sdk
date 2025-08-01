import Foundation
import Testing

@testable import Tolgee

@MainActor
struct CacheClearTests {

    @Test func testFileCacheClearAll() throws {
        let cache = FileCache()
        
        // Create test data with different descriptors
        let descriptors = [
            CacheDescriptor(language: "clear_test_en", namespace: nil, appVersionSignature: nil),
            CacheDescriptor(language: "clear_test_en", namespace: nil, appVersionSignature: "1.0.0"),
            CacheDescriptor(language: "clear_test_en", namespace: "buttons", appVersionSignature: nil),
            CacheDescriptor(language: "clear_test_es", namespace: nil, appVersionSignature: "2.0.0")
        ]
        
        let testData = "{\"test\": \"data\"}".data(using: .utf8)!
        
        // Save data for all descriptors
        for descriptor in descriptors {
            try cache.saveRecords(testData, for: descriptor)
        }
        
        // Verify all data exists
        for descriptor in descriptors {
            let loaded = cache.loadRecords(for: descriptor)
            #expect(loaded != nil, "Data should exist before clearing")
        }
        
        // Clear all cache
        try cache.clearAll()
        
        // Verify all data is gone
        for descriptor in descriptors {
            let loaded = cache.loadRecords(for: descriptor)
            #expect(loaded == nil, "Data should not exist after clearing")
        }
    }
    
    @Test func testMockCacheClearAll() throws {
        let cache = MockCache()
        
        // Create test data with different descriptors
        let descriptors = [
            CacheDescriptor(language: "mock_test_en", namespace: nil, appVersionSignature: nil),
            CacheDescriptor(language: "mock_test_en", namespace: nil, appVersionSignature: "1.0.0"),
            CacheDescriptor(language: "mock_test_en", namespace: "buttons", appVersionSignature: nil),
            CacheDescriptor(language: "mock_test_es", namespace: nil, appVersionSignature: "2.0.0")
        ]
        
        let testData = "{\"test\": \"mock_data\"}".data(using: .utf8)!
        
        // Save data for all descriptors
        for descriptor in descriptors {
            cache.saveRecords(testData, for: descriptor)
        }
        
        // Verify all data exists
        for descriptor in descriptors {
            let loaded = cache.loadRecords(for: descriptor)
            #expect(loaded != nil, "Data should exist before clearing")
        }
        
        // Clear all cache
        try cache.clearAll()
        
        // Verify all data is gone
        for descriptor in descriptors {
            let loaded = cache.loadRecords(for: descriptor)
            #expect(loaded == nil, "Data should not exist after clearing")
        }
        
        // Verify using MockCache helper methods
        #expect(cache.cachedDescriptors.isEmpty, "MockCache should report no cached descriptors")
    }
    
    @Test func testClearAllOnEmptyCache() throws {
        let fileCache = FileCache()
        let mockCache = MockCache()
        
        // Should not throw when clearing empty caches
        try fileCache.clearAll()
        try mockCache.clearAll()
        
        // Verify they're still empty
        let testDescriptor = CacheDescriptor(language: "empty_test", namespace: nil, appVersionSignature: nil)
        #expect(fileCache.loadRecords(for: testDescriptor) == nil)
        #expect(mockCache.loadRecords(for: testDescriptor) == nil)
    }
}
