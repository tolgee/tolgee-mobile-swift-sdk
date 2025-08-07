import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class FetchCdnService: Sendable {

    struct CdnFile {
        var path: String
        var etag: String?
    }

    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    func fetchFiles(
        from cdnURL: URL,
        files: [CdnFile]
    ) async throws -> [String: (Data, URLResponse)] {
        var results: [String: (Data, URLResponse)] = [:]

        // Use task group to fetch all files in parallel
        try await withThrowingTaskGroup(of: (String, (Data, URLResponse)).self) { group in
            // Add tasks for each file path
            for file in files {
                let urlSession = self.urlSession
                group.addTask {
                    let url = cdnURL.appending(component: file.path)
                    let request = URLRequest(url: url)
                    if let etag = file.etag {
                        var request = URLRequest(url: url)
                        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                    }
                    let result = try await urlSession.data(for: request)
                    return (file.path, result)
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
