import Foundation
import Testing

@testable import Tolgee

struct CacheTests {

    @Test func testMockCacheBasicOperations() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "en", namespace: nil)
        let testData = "test data".data(using: .utf8)!

        // Initially should be empty
        #expect(await cache.loadRecords(for: descriptor) == nil)
        #expect(await !cache.contains(descriptor))

        // Save data
        await cache.saveRecords(testData, for: descriptor)

        // Should now contain the data
        #expect(await cache.contains(descriptor))
        let loadedData = await cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)

        // Should appear in cached descriptors
        let descriptors = await cache.cachedDescriptors
        #expect(descriptors.contains(descriptor))
    }

    @Test func testMockCacheWithNamespace() async throws {
        let cache = MockCache()
        let baseDescriptor = CacheDescriptor(language: "en", namespace: nil)
        let namespaceDescriptor = CacheDescriptor(language: "en", namespace: "common")

        let baseData = "base data".data(using: .utf8)!
        let namespaceData = "namespace data".data(using: .utf8)!

        // Save different data for base and namespace
        await cache.saveRecords(baseData, for: baseDescriptor)
        await cache.saveRecords(namespaceData, for: namespaceDescriptor)

        // Should load correct data for each
        let loadedBase = await cache.loadRecords(for: baseDescriptor)
        let loadedNamespace = await cache.loadRecords(for: namespaceDescriptor)

        #expect(loadedBase == baseData)
        #expect(loadedNamespace == namespaceData)
        #expect(loadedBase != loadedNamespace)
    }

    @Test func testMockCachePreload() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "cs", namespace: "test")
        let testData = "preloaded data".data(using: .utf8)!

        // Preload data
        await cache.preload(testData, for: descriptor)

        // Should be able to load it
        let loadedData = await cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testMockCacheClear() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "fr", namespace: nil)
        let testData = "test data".data(using: .utf8)!

        // Save data
        await cache.saveRecords(testData, for: descriptor)
        #expect(await cache.contains(descriptor))

        // Clear cache
        await cache.clear()

        // Should be empty
        #expect(await !cache.contains(descriptor))
        #expect(await cache.loadRecords(for: descriptor) == nil)
        #expect(await cache.cachedDescriptors.isEmpty)
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
