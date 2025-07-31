import Foundation
import Testing

@testable import Tolgee

@MainActor
struct FetchCdnServiceTests {

    let cdnURL = URL(string: "https://cdn.tolg.ee/60ffdb64294ad33e0cc5076cfa71efe2")!

    @Test func testFetchFilesBasic() async throws {
        let service = FetchCdnService()

        // Test fetching basic language file
        let results = try await service.fetchFiles(
            from: cdnURL,
            filePaths: ["cs.json"]
        )

        // Should have base translation data
        #expect(results["cs.json"] != nil)
        #expect(results["cs.json"]!.count > 0)
    }

    @Test func testFetchFilesWithMultiplePaths() async throws {
        let service = FetchCdnService()

        // Test fetching with multiple file paths
        let results = try await service.fetchFiles(
            from: cdnURL,
            filePaths: ["cs.json", "Localizable2/cs.json"]
        )

        // Should have both files
        #expect(results["cs.json"] != nil)
        #expect(results["Localizable2/cs.json"] != nil)
        #expect(results["cs.json"]!.count > 0)
        #expect(results["Localizable2/cs.json"]!.count > 0)
    }

    @Test func testFetchFilesInvalidPath() async throws {
        let service = FetchCdnService()

        // Test with non-existent file - should throw an error
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: cdnURL,
                filePaths: ["invalid-file.json"]
            )
        }
    }

    @Test func testFetchFilesInvalidURL() async throws {
        let service = FetchCdnService()
        let invalidURL = URL(string: "https://invalid.domain.tld")!

        // Test with invalid CDN URL - should throw an error
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: invalidURL,
                filePaths: ["cs.json"]
            )
        }
    }

    @Test func testFetchFilesParseJSON() async throws {
        let service = FetchCdnService()

        // Fetch and verify we can parse the JSON
        let results = try await service.fetchFiles(
            from: cdnURL,
            filePaths: ["cs.json"]
        )

        guard let baseData = results["cs.json"] else {
            throw TolgeeError.translationNotFound
        }

        // Verify we can decode the JSON
        let decoder = JSONDecoder()
        let translations = try decoder.decode([String: String].self, from: baseData)

        #expect(!translations.isEmpty)
        #expect(translations["Hello, world!"] == "Ahoj světe!")
    }

    @Test func testFetchFilesPartialFailure() async throws {
        let service = FetchCdnService()

        // Test with one valid file and one invalid file
        // This should fail entirely because one of the downloads fails
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: cdnURL,
                filePaths: ["cs.json", "NonExistentFile.json"]
            )
        }
    }
}
