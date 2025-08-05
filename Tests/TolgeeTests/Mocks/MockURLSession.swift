import Foundation

@testable import Tolgee

/// Mock URL session for testing
actor MockURLSession: URLSessionProtocol {
    var mockResponses: [URL: Result<Data, Error>] = [:]
    var requestedURLs: [URL] = []

    init() {}

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        requestedURLs.append(url)

        guard let response = mockResponses[url] else {
            throw URLError(.badURL)
        }

        switch response {
        case .success(let data):
            let urlResponse =
                HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ) ?? URLResponse()
            return (data, urlResponse)
        case .failure(let error):
            throw error
        }
    }

    /// Helper method to set up mock responses
    func setMockResponse(for url: URL, result: Result<Data, Error>) {
        mockResponses[url] = result
    }

    /// Helper method to set up successful mock response with JSON data
    func setMockJSONResponse(for url: URL, json: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        setMockResponse(for: url, result: .success(data))
    }

    /// Helper method to set up successful mock response with simple string JSON data
    func setMockJSONResponse(for url: URL, json: [String: String]) throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        setMockResponse(for: url, result: .success(data))
    }

    /// Helper method to set up error response
    func setMockError(for url: URL, error: Error) {
        setMockResponse(for: url, result: .failure(error))
    }

    /// Reset all mock data
    func reset() {
        mockResponses.removeAll()
        requestedURLs.removeAll()
    }
}
