import Foundation
import Testing

@testable import Tolgee

struct CacheTests {

    @Test func testMockCacheBasicOperations() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "en", namespace: nil)
        let testData = "test data".data(using: .utf8)!

        // Initially should be empty
        #expect(cache.loadRecords(for: descriptor) == nil)
        #expect(!cache.contains(descriptor))

        // Save data
        cache.saveRecords(testData, for: descriptor)

        // Should now contain the data
        #expect(cache.contains(descriptor))
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)

        // Should appear in cached descriptors
        let descriptors = cache.cachedDescriptors
        #expect(descriptors.contains(descriptor))
    }

    @Test func testMockCacheWithNamespace() async throws {
        let cache = MockCache()
        let baseDescriptor = CacheDescriptor(language: "en", namespace: nil)
        let namespaceDescriptor = CacheDescriptor(language: "en", namespace: "common")

        let baseData = "base data".data(using: .utf8)!
        let namespaceData = "namespace data".data(using: .utf8)!

        // Save different data for base and namespace
        cache.saveRecords(baseData, for: baseDescriptor)
        cache.saveRecords(namespaceData, for: namespaceDescriptor)

        // Should load correct data for each
        let loadedBase = cache.loadRecords(for: baseDescriptor)
        let loadedNamespace = cache.loadRecords(for: namespaceDescriptor)

        #expect(loadedBase == baseData)
        #expect(loadedNamespace == namespaceData)
        #expect(loadedBase != loadedNamespace)
    }

    @Test func testMockCachePreload() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "cs", namespace: "test")
        let testData = "preloaded data".data(using: .utf8)!

        // Preload data
        cache.preload(testData, for: descriptor)

        // Should be able to load it
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testMockCacheClear() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "fr", namespace: nil)
        let testData = "test data".data(using: .utf8)!

        // Save data
        cache.saveRecords(testData, for: descriptor)
        #expect(cache.contains(descriptor))

        // Clear cache
        cache.clear()

        // Should be empty
        #expect(!cache.contains(descriptor))
        #expect(cache.loadRecords(for: descriptor) == nil)
        #expect(cache.cachedDescriptors.isEmpty)
    }

    @Test func testFileCacheBasicOperations() throws {
        let cache = FileCache()
        let descriptor = CacheDescriptor(language: "en", namespace: nil)
        let testData = "test file data".data(using: .utf8)!

        // Save data
        cache.saveRecords(testData, for: descriptor)

        // Should be able to load it
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testFileCacheWithNamespace() throws {
        let cache = FileCache()
        let baseDescriptor = CacheDescriptor(language: "de", namespace: nil)
        let namespaceDescriptor = CacheDescriptor(language: "de", namespace: "errors")

        let baseData = "base file data".data(using: .utf8)!
        let namespaceData = "namespace file data".data(using: .utf8)!

        // Save different data for base and namespace
        cache.saveRecords(baseData, for: baseDescriptor)
        cache.saveRecords(namespaceData, for: namespaceDescriptor)

        // Should load correct data for each
        let loadedBase = cache.loadRecords(for: baseDescriptor)
        let loadedNamespace = cache.loadRecords(for: namespaceDescriptor)

        #expect(loadedBase == baseData)
        #expect(loadedNamespace == namespaceData)
        #expect(loadedBase != loadedNamespace)
    }
}
