import Foundation
import Testing

@testable import Tolgee

/// The language of a bundle lookup comes from the bundle the string is read from, not from the
/// bundle Tolgee detects the app language in. `Bundle.module` plays the app here (en, cs, pt-BR,
/// zh-Hans) and a ``FixtureBundle`` plays a package with a different set of localizations.
@MainActor
struct LookupBundleLanguageTests {

    let key = "Hello, world!"

    private func makeTolgee() -> Tolgee {
        Tolgee(
            urlSession: MockURLSession(),
            cache: MockCache(),
            appVersionSignature: "1.0.0-1",
            bundleForLanguageDetection: .module
        )
    }

    // MARK: - `locale:` argument of translate()

    @Test func providedLocaleUsesLocalizationOnlyTheLookupBundleHas() throws {
        let package = try FixtureBundle(localizations: [
            "en": [key: "[package] Hello, world!"],
            "de": [key: "[package] Hallo, Welt!"],
        ])
        let tolgee = makeTolgee()

        // German is not among the localizations of the detection bundle.
        #expect(
            tolgee.translate(key, bundle: package.bundle, locale: Locale(identifier: "de"))
                == "[package] Hallo, Welt!")
    }

    @Test func providedLocaleMissingFromLookupBundleUsesItsDefaultLookup() throws {
        let package = try FixtureBundle(localizations: [
            "en": [key: "[package] Hello, world!"]
        ])
        let tolgee = makeTolgee()

        // Czech is a localization of the detection bundle, but not of the bundle being read.
        // The same as with a custom locale set on the SDK, the bundle's own lookup decides.
        #expect(
            tolgee.translate(key, bundle: package.bundle, locale: Locale(identifier: "cs"))
                == "[package] Hello, world!")
    }

    // MARK: - Custom locale set on the SDK

    @Test func customLocaleReadsEachBundlesOwnLocalization() throws {
        let package = try FixtureBundle(localizations: [
            "en": [key: "[package] Hello, world!"],
            "cs": [key: "[package] Ahoj, světe!"],
        ])
        let tolgee = makeTolgee()
        tolgee.initialize(
            cdn: URL(string: "https://cdn.example.com")!, locale: Locale(identifier: "cs_CZ"))

        // The app bundle is read first, so its Czech bundle is the one that would be reused.
        #expect(tolgee.translate(key, bundle: .module) == "[local] Ahoj, světe!")
        #expect(tolgee.translate(key, bundle: package.bundle) == "[package] Ahoj, světe!")
        #expect(tolgee.translate(key, bundle: .module) == "[local] Ahoj, světe!")
    }

    @Test func customLocaleMatchesRegionVariantPerBundle() throws {
        // The detection bundle calls its Portuguese "pt-br", the package calls it "pt".
        let package = try FixtureBundle(localizations: [
            "en": [key: "[package] Hello, world!"],
            "pt": [key: "[package] Olá, mundo!"],
        ])
        let tolgee = makeTolgee()
        tolgee.initialize(
            cdn: URL(string: "https://cdn.example.com")!, locale: Locale(identifier: "pt_BR"))

        #expect(tolgee.translate(key, bundle: .module) == "[local] Olá, mundo!")
        #expect(tolgee.translate(key, bundle: package.bundle) == "[package] Olá, mundo!")
    }

    @Test func customLocaleMissingFromLookupBundleUsesItsDefaultLookup() throws {
        let package = try FixtureBundle(localizations: [
            "en": [key: "[package] Hello, world!"]
        ])
        let tolgee = makeTolgee()
        tolgee.initialize(
            cdn: URL(string: "https://cdn.example.com")!, locale: Locale(identifier: "cs_CZ"))

        #expect(tolgee.translate(key, bundle: package.bundle) == "[package] Hello, world!")
    }
}
