import Foundation

struct CacheDescriptor: Sendable, Hashable {
    var language: String
    var namespace: String?
    var appVersionSignature: String?
}

protocol CacheProcotol: Sendable {
    func loadRecords(for descriptor: CacheDescriptor) -> Data?
    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) throws
    func clearAll() throws
}

final class FileCache: CacheProcotol {
    private let cacheDirectoryName = "TolgeeCache"

    private var cacheDirectory: URL? {
        guard
            let appSupportDir = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }
        return appSupportDir.appendingPathComponent(cacheDirectoryName)
    }

    private func cacheFileURL(for descriptor: CacheDescriptor) -> URL? {
        guard let cacheDirectory = cacheDirectory else { return nil }

        let filename: String
        let baseFilename: String

        if let namespace = descriptor.namespace {
            baseFilename = "\(namespace)_\(descriptor.language)"
        } else {
            baseFilename = descriptor.language
        }

        if let appVersionSignature = descriptor.appVersionSignature {
            filename = "\(baseFilename)_\(appVersionSignature).json"
        } else {
            filename = "\(baseFilename).json"
        }

        return cacheDirectory.appendingPathComponent(filename)
    }

    func loadRecords(for descriptor: CacheDescriptor) -> Data? {
        guard let cacheFileURL = cacheFileURL(for: descriptor),
            FileManager.default.fileExists(atPath: cacheFileURL.path)
        else {
            return nil
        }

        do {
            return try Data(contentsOf: cacheFileURL)
        } catch {
            return nil
        }
    }

    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) throws {
        guard let cacheDirectory = cacheDirectory,
            let cacheFileURL = cacheFileURL(for: descriptor)
        else {
            return
        }

        // Create cache directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Write data to cache file
        try data.write(to: cacheFileURL)
    }

    func clearAll() throws {
        guard let cacheDirectory = cacheDirectory else { return }

        // Check if cache directory exists
        guard FileManager.default.fileExists(atPath: cacheDirectory.path) else {
            return  // Nothing to clear
        }

        // Remove the entire cache directory and its contents
        try FileManager.default.removeItem(at: cacheDirectory)
    }
}
