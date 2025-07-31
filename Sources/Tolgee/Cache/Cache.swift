import Foundation

struct CacheDescriptor: Sendable, Hashable {
    var language: String
    var namespace: String?
}

protocol CacheProcotol: Sendable {
    func loadRecords(for descriptor: CacheDescriptor) -> Data?
    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) throws
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
        if let namespace = descriptor.namespace {
            filename = "\(namespace)_\(descriptor.language).json"
        } else {
            filename = "\(descriptor.language).json"
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
}
