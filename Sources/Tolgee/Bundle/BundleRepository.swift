import Foundation

/// A repository for caching and retrieving localized bundles by language identifier.
///
/// This class manages the loading and caching of language-specific resource bundles,
/// ensuring that each bundle is loaded only once and reused for subsequent requests.
@MainActor
final class BundleRepository {

    private var bundles: [String: Bundle] = [:]

    /// Retrieves a localized bundle for the specified language.
    ///
    /// This method searches for a bundle matching the provided language identifier within the
    /// reference bundle's resources. If found, the bundle is cached for future use. If a cached
    /// bundle exists, it is returned immediately.
    ///
    /// - Parameters:
    ///   - supportedLanguage: The language identifier to look up (e.g., "en", "pt-br", "zh-hans").
    ///                        **Must be lower-cased** to match the `.lproj` directory naming convention.
    ///   - referenceBundle: The bundle containing the localization resources to search within.
    /// - Returns: The localized bundle if found, or nil if no matching localization exists.
    func bundle(for supportedLanguage: String, referenceBundle: Bundle) -> Bundle? {

        if let bundle = bundles[supportedLanguage] {
            return bundle
        }

        if let path = referenceBundle.path(
            forResource: supportedLanguage, ofType: "lproj"
        ) {
            if let bundle = Bundle(path: path) {
                bundles[supportedLanguage] = bundle
                return bundle
            }
        }

        return nil
    }
}
