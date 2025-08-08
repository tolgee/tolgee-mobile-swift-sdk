import Foundation
import Testing

@testable import Tolgee

struct FileCacheTests {

    let cdnURL = URL(string: "https://cdn.example.com")!.absoluteString

    // Helper method to create a fresh FileCache and clear any existing cache
    func createCleanFileCache() throws -> FileCache {
        let cache = FileCache()
        try cache.clearAll()
        return cache
    }

    @Test func testFileCacheBasicOperations() async throws {
        let cache = try createCleanFileCache()
        let descriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let testData = "test data".data(using: .utf8)!

        // Initially should be empty
        #expect(cache.loadRecords(for: descriptor) == nil)

        // Save data
        try cache.saveRecords(testData, for: descriptor)

        // Should now contain the data
        let loadedData = cache.loadRecords(for: descriptor)
        #expect(loadedData == testData)
    }

    @Test func testFileCacheWithNamespace() async throws {
        let cache = try createCleanFileCache()
        let baseDescriptor = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let namespaceDescriptor = CacheDescriptor(
            language: "en", namespace: "common", appVersionSignature: nil, cdn: cdnURL)

        let baseData = "base data".data(using: .utf8)!
        let namespaceData = "namespace data".data(using: .utf8)!

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

    @Test func testFileCacheWithAppVersionSignature() async throws {
        let cache = try createCleanFileCache()
        let descriptor1 = CacheDescriptor(
            language: "fr", namespace: nil, appVersionSignature: "1.0.0", cdn: cdnURL)
        let descriptor2 = CacheDescriptor(
            language: "fr", namespace: nil, appVersionSignature: "2.0.0", cdn: cdnURL)

        let data1 = "version 1.0.0 data".data(using: .utf8)!
        let data2 = "version 2.0.0 data".data(using: .utf8)!

        // Save data for different app versions
        try cache.saveRecords(data1, for: descriptor1)
        try cache.saveRecords(data2, for: descriptor2)

        // Should load correct data for each version
        let loadedData1 = cache.loadRecords(for: descriptor1)
        let loadedData2 = cache.loadRecords(for: descriptor2)

        #expect(loadedData1 == data1)
        #expect(loadedData2 == data2)
        #expect(loadedData1 != loadedData2)
    }

    @Test func testFileCacheClearAll() async throws {
        let cache = try createCleanFileCache()
        let descriptor = CacheDescriptor(
            language: "fr", namespace: nil, appVersionSignature: nil, cdn: cdnURL)
        let testData = "test data".data(using: .utf8)!

        // Save data
        try cache.saveRecords(testData, for: descriptor)
        #expect(cache.loadRecords(for: descriptor) == testData)

        // Clear cache
        try cache.clearAll()

        // Should be empty
        #expect(cache.loadRecords(for: descriptor) == nil)
    }

    @Test func testFileCacheWithDifferentCDNs() throws {
        let cache = try createCleanFileCache()
        let cdn1 = "https://cdn1.example.com"
        let cdn2 = "https://cdn2.example.com"

        let descriptor1 = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdn1)
        let descriptor2 = CacheDescriptor(
            language: "en", namespace: nil, appVersionSignature: nil, cdn: cdn2)

        let data1 = "CDN 1 data".data(using: .utf8)!
        let data2 = "CDN 2 data".data(using: .utf8)!

        // Save data for different CDNs
        try cache.saveRecords(data1, for: descriptor1)
        try cache.saveRecords(data2, for: descriptor2)

        // Should load correct data for each CDN
        let loadedData1 = cache.loadRecords(for: descriptor1)
        let loadedData2 = cache.loadRecords(for: descriptor2)

        #expect(loadedData1 == data1)
        #expect(loadedData2 == data2)
        #expect(loadedData1 != loadedData2)
    }

    @Test func testFileCacheETagOperations() throws {
        let cache = try createCleanFileCache()
        let etagDescriptor = CdnEtagDescriptor(language: "en", namespace: nil, cdn: cdnURL)
        let etag = "test-etag-123"

        // Initially should be empty
        #expect(cache.loadCdnEtag(for: etagDescriptor) == nil)

        // Save ETag
        try cache.saveCdnEtag(etagDescriptor, etag: etag)

        // Should be able to load it
        let loadedEtag = cache.loadCdnEtag(for: etagDescriptor)
        #expect(loadedEtag == etag)
    }

    @Test func testFileCacheETagWithNamespace() throws {
        let cache = try createCleanFileCache()
        let baseEtagDescriptor = CdnEtagDescriptor(language: "de", namespace: nil, cdn: cdnURL)
        let namespaceEtagDescriptor = CdnEtagDescriptor(
            language: "de", namespace: "errors", cdn: cdnURL)

        let baseEtag = "base-etag-456"
        let namespaceEtag = "namespace-etag-789"

        // Save different ETags for base and namespace
        try cache.saveCdnEtag(baseEtagDescriptor, etag: baseEtag)
        try cache.saveCdnEtag(namespaceEtagDescriptor, etag: namespaceEtag)

        // Should load correct ETag for each
        let loadedBaseEtag = cache.loadCdnEtag(for: baseEtagDescriptor)
        let loadedNamespaceEtag = cache.loadCdnEtag(for: namespaceEtagDescriptor)

        #expect(loadedBaseEtag == baseEtag)
        #expect(loadedNamespaceEtag == namespaceEtag)
        #expect(loadedBaseEtag != loadedNamespaceEtag)
    }

    @Test func testFileCacheETagClearAll() throws {
        let cache = try createCleanFileCache()
        let etagDescriptor = CdnEtagDescriptor(language: "es", namespace: nil, cdn: cdnURL)
        let etag = "test-etag-clear"

        // Save ETag
        try cache.saveCdnEtag(etagDescriptor, etag: etag)
        #expect(cache.loadCdnEtag(for: etagDescriptor) == etag)

        // Clear all cache (should also clear ETags)
        try cache.clearAll()

        // ETag should be gone
        #expect(cache.loadCdnEtag(for: etagDescriptor) == nil)
    }
}
