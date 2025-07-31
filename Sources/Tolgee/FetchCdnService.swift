import Foundation
import OSLog

/// Service responsible for fetching translation files from CDN
@MainActor
public class FetchCdnService {

    /// Fetches files from CDN in parallel
    /// - Parameters:
    ///   - cdnURL: Base CDN URL
    ///   - filePaths: List of file paths to download relative to the CDN URL
    /// - Returns: Dictionary of file paths to downloaded data
    /// - Throws: Error if any of the downloads fail
    public func fetchFiles(
        from cdnURL: URL,
        filePaths: [String]
    ) async throws -> [String: Data] {
        var results: [String: Data] = [:]

        // Use task group to fetch all files in parallel
        try await withThrowingTaskGroup(of: (String, Data).self) { group in
            // Add tasks for each file path
            for filePath in filePaths {
                group.addTask {
                    let data = try await URLSession.shared.data(
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
