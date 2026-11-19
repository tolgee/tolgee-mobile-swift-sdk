import Foundation

/// A throwaway bundle on disk with its own set of localizations.
///
/// Stands in for a Swift package or a framework whose localizations differ from the ones of
/// the bundle Tolgee detects the language from. The directory is removed on deinit.
final class FixtureBundle {
    let bundle: Bundle
    private let url: URL

    /// - Parameter localizations: Strings of the `Localizable` table, keyed by `.lproj` name.
    init(localizations: [String: [String: String]]) throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TolgeeFixture-\(UUID().uuidString).bundle")

        for (language, strings) in localizations {
            let lproj = url.appendingPathComponent("\(language).lproj")
            try FileManager.default.createDirectory(at: lproj, withIntermediateDirectories: true)

            let contents = strings.map { "\"\($0.key)\" = \"\($0.value)\";" }.joined(separator: "\n")
            try contents.write(
                to: lproj.appendingPathComponent("Localizable.strings"),
                atomically: true, encoding: .utf8)
        }

        guard let bundle = Bundle(url: url) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.bundle = bundle
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
