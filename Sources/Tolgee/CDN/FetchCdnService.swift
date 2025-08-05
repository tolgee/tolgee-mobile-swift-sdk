import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class FetchCdnService: Sendable {
    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

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
                    let url = cdnURL.appending(component: filePath)
                    let request = URLRequest(url: url)
                    let result = try await urlSession.data(for: request)
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
