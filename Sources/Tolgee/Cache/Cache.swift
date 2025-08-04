import Foundation

struct CacheDescriptor: Sendable, Hashable {
    var language: String
    var namespace: String?
    var appVersionSignature: String?
    var cdn: String
}

protocol CacheProtocol: Sendable {
    func loadRecords(for descriptor: CacheDescriptor) -> Data?
    func saveRecords(_ data: Data, for descriptor: CacheDescriptor) throws
    func clearAll() throws
}

final class FileCache: CacheProtocol {
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

    private func cacheDirectory(for cdn: String) -> URL? {
        guard let baseCache = cacheDirectory else { return nil }

        // URL encode the CDN string to create a safe directory name
        guard let safeCdnName = cdn.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else {
            return nil
        }

        return baseCache.appendingPathComponent(safeCdnName)
    }

    private func cacheFileURL(for descriptor: CacheDescriptor) -> URL? {
        guard let cdnCacheDirectory = cacheDirectory(for: descriptor.cdn) else { return nil }

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

        return cdnCacheDirectory.appendingPathComponent(filename)
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
        guard let cdnCacheDirectory = cacheDirectory(for: descriptor.cdn),
            let cacheFileURL = cacheFileURL(for: descriptor)
        else {
            return
        }

        // Create CDN-specific cache directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: cdnCacheDirectory,
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
