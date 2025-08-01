import Foundation
import Testing

@testable import Tolgee

@MainActor
struct CacheDebugTests {

    @Test func testCacheFilePaths() {
        let cache = FileCache()

        // Test different cache descriptors and their expected file paths
        let descriptors = [
            CacheDescriptor(language: "en", namespace: nil, appVersionSignature: nil),
            CacheDescriptor(language: "en", namespace: nil, appVersionSignature: "1.0.0-42"),
            CacheDescriptor(language: "en", namespace: "buttons", appVersionSignature: nil),
            CacheDescriptor(language: "en", namespace: "buttons", appVersionSignature: "1.0.0-42"),
        ]

        // Using reflection to access the private method for testing
        // Since we can't access private methods directly, let's create test data and see what happens
        let testData = "{}".data(using: .utf8)!

        for (index, descriptor) in descriptors.enumerated() {
            do {
                try cache.saveRecords(testData, for: descriptor)
                let loaded = cache.loadRecords(for: descriptor)
                #expect(loaded != nil, "Failed to load data for descriptor \(index): \(descriptor)")

                print("Descriptor \(index): \(descriptor)")
                print("Successfully saved and loaded")

            } catch {
                #expect(Bool(false), "Failed to save/load for descriptor \(index): \(error)")
            }
        }

        // Now test that they don't interfere with each other
        // Descriptor 0 (no version) should not load descriptor 1 (with version)
        let loadedWrong = cache.loadRecords(
            for: CacheDescriptor(
                language: "en",
                namespace: nil,
                appVersionSignature: "different-version"
            ))

        print(
            "Trying to load with different version: \(loadedWrong != nil ? "FOUND" : "NOT FOUND")")
        #expect(loadedWrong == nil, "Should not find cache for different app version")
    }
}
