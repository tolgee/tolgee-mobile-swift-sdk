import Foundation
import Testing

@testable import Tolgee

struct MockCacheTests {

    let cdnURL = URL(string: "https://cdn.example.com")!.absoluteString

    @Test func testMockCacheBasicOperations() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "en", namespace: nil, cdn: cdnURL)
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
        let baseDescriptor = CacheDescriptor(language: "en", namespace: nil, cdn: cdnURL)
        let namespaceDescriptor = CacheDescriptor(language: "en", namespace: "common", cdn: cdnURL)

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
        let descriptor = CacheDescriptor(language: "cs", namespace: "test", cdn: cdnURL)
        let testData = "preloaded data".data(using: .utf8)!

        // Preload data
        cache.preload(testData, for: descriptor)

        // Should be able to load it
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testMockCacheClear() async throws {
        let cache = MockCache()
        let descriptor = CacheDescriptor(language: "fr", namespace: nil, cdn: cdnURL)
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
        let descriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let testData = "test file data".data(using: .utf8)!

        // Save data
        try cache.saveRecords(testData, for: descriptor)

        // Should be able to load it
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testFileCacheWithNamespace() throws {
        let cache = FileCache()
        let baseDescriptor = CacheDescriptor(
            language: "de", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let namespaceDescriptor = CacheDescriptor(
            language: "de", namespace: "errors", appVersionSignature: nil, cdn: cdnURL)

        let baseData = "base file data".data(using: .utf8)!
        let namespaceData = "namespace file data".data(using: .utf8)!

        // Save different data for base and namespace
        try cache.saveRecords(baseData, for: baseDescriptor)
        try cache.saveRecords(namespaceData, for: namespaceDescriptor)

        // Should load correct data for each
        let loadedBase = cache.loadRecords(for: baseDescriptor)
        let loadedNamespace = cache.loadRecords(for: namespaceDescriptor)

        #expect(loadedBase == baseData)
        #expect(loadedNamespace == namespaceData)
        #expect(loadedBase != loadedNamespace)
    }

    @Test func testMockCacheClearOldCache() {
        let cache = MockCache()

        // Create descriptors for multiple app versions
        let noVersionDescriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let oldVersionDescriptor1 = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: "1.0.0", cdn: cdnURL)
        let oldVersionDescriptor2 = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: "1.5.0", cdn: cdnURL)
        let currentVersionDescriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: "2.0.0", cdn: cdnURL)
        let differentLanguageDescriptor = CacheDescriptor(
            language: "fr", namespace: nil, appVersionSignature: "1.0.0", cdn: cdnURL)

        let noVersionData = "no version data".data(using: .utf8)!
        let oldData1 = "old version 1.0.0 data".data(using: .utf8)!
        let oldData2 = "old version 1.5.0 data".data(using: .utf8)!
        let currentData = "current version 2.0.0 data".data(using: .utf8)!
        let differentLanguageData = "different language data".data(using: .utf8)!

        // Save data for all versions
        cache.saveRecords(noVersionData, for: noVersionDescriptor)
        cache.saveRecords(oldData1, for: oldVersionDescriptor1)
        cache.saveRecords(oldData2, for: oldVersionDescriptor2)
        cache.saveRecords(currentData, for: currentVersionDescriptor)
        cache.saveRecords(differentLanguageData, for: differentLanguageDescriptor)

        // Verify all data is saved
        #expect(cache.loadRecords(for: noVersionDescriptor) == noVersionData)
        #expect(cache.loadRecords(for: oldVersionDescriptor1) == oldData1)
        #expect(cache.loadRecords(for: oldVersionDescriptor2) == oldData2)
        #expect(cache.loadRecords(for: currentVersionDescriptor) == currentData)
        #expect(cache.loadRecords(for: differentLanguageDescriptor) == differentLanguageData)

        // Clear old cache for current version
        cache.clearOldCache(descriptor: currentVersionDescriptor)

        // No version and old versions should be deleted
        #expect(cache.loadRecords(for: noVersionDescriptor) == nil)
        #expect(cache.loadRecords(for: oldVersionDescriptor1) == nil)
        #expect(cache.loadRecords(for: oldVersionDescriptor2) == nil)

        // Current version should still exist
        #expect(cache.loadRecords(for: currentVersionDescriptor) == currentData)

        // Different language should not be affected
        #expect(cache.loadRecords(for: differentLanguageDescriptor) == differentLanguageData)
    }

    @Test func testMockCacheClearOldCacheWithNamespace() {
        let cache = MockCache()

        // Create descriptors with namespace for multiple versions
        let oldVersionDescriptor = CacheDescriptor(
            language: "de", namespace: "common", appVersionSignature: "1.0.0", cdn: cdnURL)
        let currentVersionDescriptor = CacheDescriptor(
            language: "de", namespace: "common", appVersionSignature: "2.0.0", cdn: cdnURL)

        // Also create descriptors for different namespace/language to ensure they're not affected
        let differentNamespaceDescriptor = CacheDescriptor(
            language: "de", namespace: "errors", appVersionSignature: "1.0.0", cdn: cdnURL)
        let differentLanguageDescriptor = CacheDescriptor(
            language: "fr", namespace: "common", appVersionSignature: "1.0.0", cdn: cdnURL)

        let oldData = "old version data".data(using: .utf8)!
        let currentData = "current version data".data(using: .utf8)!
        let differentNamespaceData = "different namespace data".data(using: .utf8)!
        let differentLanguageData = "different language data".data(using: .utf8)!

        // Save all data
        cache.saveRecords(oldData, for: oldVersionDescriptor)
        cache.saveRecords(currentData, for: currentVersionDescriptor)
        cache.saveRecords(differentNamespaceData, for: differentNamespaceDescriptor)
        cache.saveRecords(differentLanguageData, for: differentLanguageDescriptor)

        // Clear old cache for current version
        cache.clearOldCache(descriptor: currentVersionDescriptor)

        // Old version with same namespace should be deleted
        #expect(cache.loadRecords(for: oldVersionDescriptor) == nil)

        // Current version should still exist
        #expect(cache.loadRecords(for: currentVersionDescriptor) == currentData)

        // Different namespace and language should not be affected
        #expect(cache.loadRecords(for: differentNamespaceDescriptor) == differentNamespaceData)
        #expect(cache.loadRecords(for: differentLanguageDescriptor) == differentLanguageData)
    }

    @Test func testMockCacheClearOldCacheWithoutAppVersionSignature() {
        let cache = MockCache()

        // Create descriptor without app version signature
        let descriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let testData = "test data".data(using: .utf8)!

        // Save data
        cache.saveRecords(testData, for: descriptor)
        #expect(cache.loadRecords(for: descriptor) == testData)

        // Call clearOldCache with descriptor without appVersionSignature
        // This should do nothing (no other entries to remove)
        cache.clearOldCache(descriptor: descriptor)

        // Data should still exist
        #expect(cache.loadRecords(for: descriptor) == testData)
    }
}
