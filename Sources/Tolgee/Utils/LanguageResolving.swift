import Foundation

/// Resolves the best matching language from a bundle's available localizations for a given locale.
///
/// Uses Bundle's preferred localization matching algorithm to find the most appropriate language
/// from the bundle's supported localizations, excluding the Base localization.
///
/// - Parameters:
///   - locale: The locale to resolve the language for
///   - bundle: The bundle containing the localizations to match against
/// - Returns: The identifier of the matched localization, or nil if no match is found
func resolveLanguage(for locale: Locale, in bundle: Bundle) -> String? {
    // Get all supported localizations (excluding Base)
    let supportedLocalizations = bundle.localizations.filter { $0 != "Base" }

    // Use Bundle's matching algorithm
    let preferredLanguages = [locale.identifier]
    let matchedLocalizations = Bundle.preferredLocalizations(
        from: supportedLocalizations,
        forPreferences: preferredLanguages
    )

    return matchedLocalizations.first
}

/// Checks if a locale matches a given language by comparing their base language codes.
///
/// Compares the primary language subtag (before the first hyphen/underscore) of both
/// the locale identifier and the language string. Normalizes underscores to hyphens
/// for consistent comparison.
///
/// - Parameters:
///   - locale: The locale to check
///   - language: The language string to match against (e.g., "en-US", "cs")
/// - Returns: True if the base language codes match, false otherwise
func doesLocaleMatchLanguage(_ locale: Locale, language: String) -> Bool {
    guard
        let bareLanguageFromLocale = locale.identifier.replacingOccurrences(of: "_", with: "-")
            .split(separator: "-").first
    else {
        return false
    }

    guard let bareLanguageFromLanguage = language.split(separator: "-").first else {
        return false
    }

    return bareLanguageFromLocale == bareLanguageFromLanguage
}
