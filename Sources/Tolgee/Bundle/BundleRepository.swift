import Foundation

@MainActor
final class BundleRepository {

    private var bundles: [Locale: Bundle] = [:]

    func bundle(for locale: Locale, referenceBundle: Bundle) -> Bundle? {

        if let bundle = bundles[locale] {
            return bundle
        }

        if let path = referenceBundle.path(
            forResource: locale.identifier.replacingOccurrences(of: "_", with: "-"), ofType: "lproj"
        ) {
            if let bundle = Bundle(path: path) {
                bundles[locale] = bundle
                return bundle
            }
        }

        guard let languageCodeIdentifier = locale.language.languageCode?.identifier else {
            return nil
        }

        if let path = referenceBundle.path(forResource: languageCodeIdentifier, ofType: "lproj") {
            if let bundle = Bundle(path: path) {
                bundles[locale] = bundle
                return bundle
            }
        }

        return nil
    }
}
