import Foundation

protocol URLSessionProtocol: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class FetchCdnService: Sendable {
    private let urlSession: URLSessionProtocol

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
    ) async throws -> [String: (Data, URLResponse)] {
        var results: [String: (Data, URLResponse)] = [:]

        // Use task group to fetch all files in parallel
        try await withThrowingTaskGroup(of: (String, (Data, URLResponse)).self) { group in
            // Add tasks for each file path
            for filePath in filePaths {
                let urlSession = self.urlSession
                group.addTask {
                    let result = try await urlSession.data(
                        from: cdnURL.appending(component: filePath)
                    )
                    return (filePath, result)
                }
            }

            // Process results as they complete
            for try await (filePath, result) in group {
                results[filePath] = result
            }
        }

        return results
    }
}
