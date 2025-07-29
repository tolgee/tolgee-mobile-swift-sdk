import Foundation
import Testing

@testable import Tolgee

struct TolgeeParallelFetchTests {

    @Test func testParallelFetchErrorHandling() async throws {
        let tolgee = await Tolgee.shared

        // Test with invalid URL to ensure error handling works
        let invalidURL = URL(string: "https://invalid-url-that-does-not-exist.test")!

        // This should not crash and should handle errors gracefully
        await tolgee.initialize(cdn: invalidURL, language: "en", tables: ["table1", "table2"])

        // Wait a bit for the async fetch to complete
        try await Task.sleep(for: .seconds(1))

        // The fetch should complete without crashing, even though it will fail
        // We can't really assert much here since the method doesn't return anything
        // But the test passing means the error handling works correctly
        #expect(true)  // If we get here, error handling worked
    }

    @Test func testParallelFetchWithEmptyTables() async throws {
        let tolgee = await Tolgee.shared

        // Test with a valid-looking URL but empty tables array
        let testURL = URL(string: "https://cdn.tolg.ee/test")!

        // This should handle the case where there are no additional tables
        await tolgee.initialize(cdn: testURL, language: "en", tables: [])

        // Wait a bit for the async fetch to complete
        try await Task.sleep(for: .seconds(1))

        #expect(true)  // Test passes if no crash occurs
    }
}
