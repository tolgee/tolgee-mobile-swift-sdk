import Foundation
import Testing

@testable import Tolgee

@MainActor
struct CacheAppVersionTests {

    @Test func testCacheFileNamesWithAppVersion() {
        let cache = FileCache()

        // Clean up any existing cache files first by trying to clear the cache directory
        // We'll use unique language codes to avoid conflicts with other tests
        let uniqueLanguage = "test_\(UUID().uuidString.prefix(8))"

        // Test without app version signature
        let descriptorWithoutVersion = CacheDescriptor(
            language: uniqueLanguage,
            namespace: nil,
            appVersionSignature: nil
        )

        // Test with app version signature
        let descriptorWithVersion = CacheDescriptor(
            language: uniqueLanguage,
            namespace: nil,
            appVersionSignature: "1.0.0-42"
        )

        // Test with namespace and app version
        let descriptorWithNamespaceAndVersion = CacheDescriptor(
            language: uniqueLanguage,
            namespace: "buttons",
            appVersionSignature: "1.0.0-42"
        )

        // Create some test data
        let testData = "{}".data(using: .utf8)!

        do {
            // Save with different descriptors
            try cache.saveRecords(testData, for: descriptorWithoutVersion)
            try cache.saveRecords(testData, for: descriptorWithVersion)
            try cache.saveRecords(testData, for: descriptorWithNamespaceAndVersion)

            // Verify we can load back the data
            let loadedWithoutVersion = cache.loadRecords(for: descriptorWithoutVersion)
            let loadedWithVersion = cache.loadRecords(for: descriptorWithVersion)
            let loadedWithNamespaceAndVersion = cache.loadRecords(
                for: descriptorWithNamespaceAndVersion)

            #expect(loadedWithoutVersion != nil)
            #expect(loadedWithVersion != nil)
            #expect(loadedWithNamespaceAndVersion != nil)

            // Verify that different app versions create different cache files
            // (i.e., descriptor with version shouldn't load data saved without version)
            let loadedDifferentVersion = cache.loadRecords(
                for: CacheDescriptor(
                    language: uniqueLanguage,
                    namespace: nil,
                    appVersionSignature: "2.0.0-100"
                ))

            #expect(loadedDifferentVersion == nil)

        } catch {
            #expect(Bool(false), "Cache operations should not throw: \(error)")
        }
    }

    @Test func testCacheIsolationByAppVersion() {
        let cache = FileCache()

        // Use unique language to avoid test interference
        let uniqueLanguage = "iso_\(UUID().uuidString.prefix(8))"

        let descriptorV1 = CacheDescriptor(
            language: uniqueLanguage,
            namespace: nil,
            appVersionSignature: "1.0.0-42"
        )

        let descriptorV2 = CacheDescriptor(
            language: uniqueLanguage,
            namespace: nil,
            appVersionSignature: "2.0.0-100"
        )

        let testDataV1 = "{\"key\": \"value v1\"}".data(using: .utf8)!
        let testDataV2 = "{\"key\": \"value v2\"}".data(using: .utf8)!

        do {
            // Save different data for different app versions
            try cache.saveRecords(testDataV1, for: descriptorV1)
            try cache.saveRecords(testDataV2, for: descriptorV2)

            // Verify we get the correct data for each version
            let loadedV1 = cache.loadRecords(for: descriptorV1)
            let loadedV2 = cache.loadRecords(for: descriptorV2)

            #expect(loadedV1 == testDataV1)
            #expect(loadedV2 == testDataV2)
            #expect(loadedV1 != loadedV2)

        } catch {
            #expect(Bool(false), "Cache operations should not throw: \(error)")
        }
    }
}
