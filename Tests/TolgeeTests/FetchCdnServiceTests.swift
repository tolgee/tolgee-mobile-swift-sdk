import Foundation
import Testing

@testable import Tolgee

struct FetchCdnServiceTests {

    let cdnURL = URL(string: "https://cdn.example.com")!

    @Test func testFetchFilesBasic() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)

        // Set up mock response
        let testURL = cdnURL.appending(component: "cs.json")
        try await mockSession.setMockJSONResponse(
            for: testURL, json: ["Hello, world!": "Ahoj, světe!"])

        // Test fetching basic language file
        let results = try await service.fetchFiles(
            from: cdnURL,
            files: [.init(path: "cs.json")]
        )

        // Should have base translation data
        #expect(results["cs.json"] != nil)
        #expect(results["cs.json"]!.0.count > 0)

        // Verify the correct URL was requested
        let requestedURLs = await mockSession.requestedURLs
        #expect(requestedURLs.contains(testURL))
    }

    @Test func testFetchFilesWithMultiplePaths() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)

        // Set up mock responses
        let baseURL = cdnURL.appending(component: "cs.json")
        let namespaceURL = cdnURL.appending(component: "Localizable2/cs.json")
        try await mockSession.setMockJSONResponse(
            for: baseURL, json: ["Hello, world!": "Ahoj, světe!"])
        try await mockSession.setMockJSONResponse(
            for: namespaceURL, json: ["Good morning": "Dobré ráno"])

        // Test fetching with multiple file paths
        let results = try await service.fetchFiles(
            from: cdnURL,
            files: [.init(path: "cs.json"), .init(path: "Localizable2/cs.json")]
        )

        // Should have both files
        #expect(results["cs.json"] != nil)
        #expect(results["Localizable2/cs.json"] != nil)
        #expect(results["cs.json"]!.0.count > 0)
        #expect(results["Localizable2/cs.json"]!.0.count > 0)

        // Verify both URLs were requested
        let requestedURLs = await mockSession.requestedURLs
        #expect(requestedURLs.contains(baseURL))
        #expect(requestedURLs.contains(namespaceURL))
    }

    @Test func testFetchFilesInvalidPath() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)

        // Set up mock error response
        let invalidURL = cdnURL.appending(component: "invalid-file.json")
        await mockSession.setMockError(for: invalidURL, error: URLError(.fileDoesNotExist))

        // Test with non-existent file - should throw an error
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: cdnURL,
                files: [.init(path: "invalid-file.json")]
            )
        }

        // Verify the URL was requested
        let requestedURLs = await mockSession.requestedURLs
        #expect(requestedURLs.contains(invalidURL))
    }

    @Test func testFetchFilesInvalidURL() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)
        let invalidURL = URL(string: "https://invalid.domain.tld")!

        // Set up mock error response for invalid URL
        let testURL = invalidURL.appending(component: "cs.json")
        await mockSession.setMockError(for: testURL, error: URLError(.cannotConnectToHost))

        // Test with invalid CDN URL - should throw an error
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: invalidURL,
                files: [.init(path: "cs.json")]
            )
        }

        // Verify the URL was requested
        let requestedURLs = await mockSession.requestedURLs
        #expect(requestedURLs.contains(testURL))
    }

    @Test func testFetchFilesParseJSON() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)

        // Set up mock response with specific JSON
        let testURL = cdnURL.appending(component: "cs.json")
        let testTranslations: [String: String] = [
            "Hello, world!": "Ahoj, světe!",
            "Good morning": "Dobré ráno",
            "My name is %@": "Jmenuji se %@",
        ]
        try await mockSession.setMockJSONResponse(for: testURL, json: testTranslations)

        // Fetch and verify we can parse the JSON
        let results = try await service.fetchFiles(
            from: cdnURL,
            files: [.init(path: "cs.json")]
        )

        guard let baseData = results["cs.json"] else {
            throw TolgeeError.translationNotFound
        }

        // Verify we can decode the JSON
        let decoder = JSONDecoder()
        let translations = try decoder.decode([String: String].self, from: baseData.0)

        #expect(!translations.isEmpty)
        #expect(translations["Hello, world!"] == "Ahoj, světe!")
        #expect(translations["Good morning"] == "Dobré ráno")

        // Verify the URL was requested
        let requestedURLs = await mockSession.requestedURLs
        #expect(requestedURLs.contains(testURL))
    }

    @Test func testFetchFilesPartialFailure() async throws {
        let mockSession = MockURLSession()
        let service = FetchCdnService(urlSession: mockSession)

        // Set up one successful response and one error
        let validURL = cdnURL.appending(component: "cs.json")
        let invalidURL = cdnURL.appending(component: "NonExistentFile.json")
        try await mockSession.setMockJSONResponse(for: validURL, json: ["Hello": "Ahoj"])
        await mockSession.setMockError(for: invalidURL, error: URLError(.fileDoesNotExist))

        // Test with one valid file and one invalid file
        // This should fail entirely because one of the downloads fails
        await #expect(throws: (any Error).self) {
            try await service.fetchFiles(
                from: cdnURL,
                files: [.init(path: "cs.json"), .init(path: "NonExistentFile.json")]
            )
        }

        // Verify at least one URL was requested (task group cancellation may stop some requests)
        let requestedURLs = await mockSession.requestedURLs
        #expect(!requestedURLs.isEmpty)
    }
}
