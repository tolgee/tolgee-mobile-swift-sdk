import Foundation
import OSLog

/// Protocol for URL session to enable mocking
protocol URLSessionProtocol: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

/// Extension to make URLSession conform to the protocol
extension URLSession: URLSessionProtocol {}

/// Service responsible for fetching translation files from CDN
final class FetchCdnService: Sendable {
    private let urlSession: URLSessionProtocol

    /// Initialize with a custom URL session (useful for testing)
    /// - Parameter urlSession: The URL session to use for network requests
    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    /// Fetches files from CDN in parallel
    /// - Parameters:
    ///   - cdnURL: Base CDN URL
    ///   - filePaths: List of file paths to download relative to the CDN URL
    /// - Returns: Dictionary of file paths to downloaded data
    /// - Throws: Error if any of the downloads fail
    func fetchFiles(
        from cdnURL: URL,
        filePaths: [String]
    ) async throws -> [String: Data] {
        var results: [String: Data] = [:]

        // Use task group to fetch all files in parallel
        try await withThrowingTaskGroup(of: (String, Data).self) { group in
            // Add tasks for each file path
            for filePath in filePaths {
                let urlSession = self.urlSession
                group.addTask {
                    let data = try await urlSession.data(
                        from: cdnURL.appending(component: filePath)
                    ).0
                    return (filePath, data)
                }
            }

            // Process results as they complete
            for try await (filePath, data) in group {
                results[filePath] = data
            }
        }

        return results
    }
}
