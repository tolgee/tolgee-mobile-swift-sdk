import Foundation

/// A repository for caching and retrieving localized bundles by language identifier.
///
/// This class manages the loading and caching of language-specific resource bundles,
/// ensuring that each bundle is loaded only once and reused for subsequent requests.
///
/// Every lookup is scoped to its reference bundle. The app, a Swift package and a framework each
/// carry their own set of localizations, so the same language resolves to a different `.lproj`
/// (or to none) depending on the bundle the string is read from.
@MainActor
final class BundleRepository {

    private struct LanguageKey: Hashable {
        let referenceBundlePath: String
        let language: String
    }

    private struct LocaleKey: Hashable {
        let referenceBundlePath: String
        let localeIdentifier: String
    }

    private var bundles: [LanguageKey: Bundle] = [:]
    // Holds misses too, so that a locale the bundle doesn't support is matched only once.
    private var bundlesByLocale: [LocaleKey: Bundle?] = [:]

    /// Retrieves the localized bundle a locale resolves to within the reference bundle.
    ///
    /// The locale is matched against the reference bundle's own localizations, so the result
    /// doesn't depend on what any other bundle supports. Both hits and misses are cached.
    ///
    /// - Parameters:
    ///   - locale: The locale to find a localization for (e.g., "cs_CZ", "pt-BR").
    ///   - referenceBundle: The bundle containing the localization resources to search within.
    /// - Returns: The localized bundle, or nil if the reference bundle has no localization
    ///   for the locale's language.
    func localizedBundle(for locale: Locale, in referenceBundle: Bundle) -> Bundle? {
        let cacheKey = LocaleKey(
            referenceBundlePath: referenceBundle.bundlePath, localeIdentifier: locale.identifier)

        if let cached = bundlesByLocale[cacheKey] {
            return cached
        }

        var localizedBundle: Bundle? = nil
        if let language = resolveLanguage(for: locale, in: referenceBundle),
            doesLocaleMatchLanguage(locale, language: language)
        {
            localizedBundle = bundle(for: language, referenceBundle: referenceBundle)
        }

        bundlesByLocale.updateValue(localizedBundle, forKey: cacheKey)
        return localizedBundle
    }

    /// Retrieves a localized bundle for the specified language.
    ///
    /// This method searches for a bundle matching the provided language identifier within the
    /// reference bundle's resources. If found, the bundle is cached for future use. If a cached
    /// bundle exists, it is returned immediately.
    ///
    /// - Parameters:
    ///   - supportedLanguage: The language identifier to look up (e.g., "en", "pt-BR", "zh-Hans").
    ///                        Must match the `.lproj` directory name as the reference bundle
    ///                        reports it in `localizations`, which is what `resolveLanguage(for:in:)`
    ///                        returns.
    ///   - referenceBundle: The bundle containing the localization resources to search within.
    /// - Returns: The localized bundle if found, or nil if no matching localization exists.
    func bundle(for supportedLanguage: String, referenceBundle: Bundle) -> Bundle? {
        let cacheKey = LanguageKey(
            referenceBundlePath: referenceBundle.bundlePath, language: supportedLanguage)

        if let bundle = bundles[cacheKey] {
            return bundle
        }

        if let path = referenceBundle.path(
            forResource: supportedLanguage, ofType: "lproj"
        ) {
            if let bundle = Bundle(path: path) {
                bundles[cacheKey] = bundle
                return bundle
            }
        }

        return nil
    }
}
