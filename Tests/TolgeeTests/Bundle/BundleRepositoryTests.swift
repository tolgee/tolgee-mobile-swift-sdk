import Foundation
import Testing

@testable import Tolgee

@MainActor
struct BundleRepositoryTests {

    @Test func testBundleForExactLocaleMatch() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "en")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        print("aaa")

        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Hello, world!")
    }

    @Test func testBundleForLocaleWithRegion() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "pt-BR")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        print("aaa")

        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Hello, world!")
    }

    @Test func testBundleWithUnderscoreSeparatorNormalization() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "pt_BR")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should normalize underscore to hyphen and find pt-br
        #expect(result != nil)
        #expect(result?.localizations.contains("pt-br") == true)
    }

    @Test func testBundleFallsBackToLanguageCode() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "en-GB")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should fall back to "en" since en-GB doesn't exist
        #expect(result != nil)
        #expect(result?.localizations.contains("en") == true)
    }

    @Test func testBundleCaching() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "en")

        let firstResult = repository.bundle(for: locale, referenceBundle: referenceBundle)
        let secondResult = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should return the same cached bundle instance
        #expect(firstResult != nil)
        #expect(secondResult != nil)
        #expect(firstResult === secondResult)
    }

    @Test func testBundleCachingWithDifferentLocales() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let enLocale = Locale(identifier: "en")
        let csLocale = Locale(identifier: "cs")

        let enBundle = repository.bundle(for: enLocale, referenceBundle: referenceBundle)
        let csBundle = repository.bundle(for: csLocale, referenceBundle: referenceBundle)

        // Should return different bundles for different locales
        #expect(enBundle != nil)
        #expect(csBundle != nil)
        #expect(enBundle !== csBundle)
    }

    @Test func testBundleForCzechLocale() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "cs")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(result?.localizations.contains("cs") == true)
    }

    @Test func testBundleForCzechWithRegion() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "cs-CZ")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should fall back to "cs" since cs-CZ doesn't exist
        #expect(result != nil)
        #expect(result?.localizations.contains("cs") == true)
    }

    @Test func testBundleForSimplifiedChinese() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "zh-Hans")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(result?.localizations.contains("zh-hans") == true)
    }

    @Test func testBundleReturnsNilForUnsupportedLanguage() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "xyz")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should return nil for unsupported language
        #expect(result == nil)
    }

    @Test func testBundleForPortugueseBaseLanguage() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "pt")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should find pt-br when looking for base "pt"
        #expect(result != nil)
        #expect(result?.localizations.contains("pt-br") == true)
    }

    @Test func testBundleCachingWithRegionalVariants() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let enUSLocale = Locale(identifier: "en-US")
        let enGBLocale = Locale(identifier: "en-GB")

        let enUSBundle = repository.bundle(for: enUSLocale, referenceBundle: referenceBundle)
        let enGBBundle = repository.bundle(for: enGBLocale, referenceBundle: referenceBundle)

        // Both should cache their own lookups
        #expect(enUSBundle != nil)
        #expect(enGBBundle != nil)

        // Verify caching works for repeat calls
        let enUSBundle2 = repository.bundle(for: enUSLocale, referenceBundle: referenceBundle)
        let enGBBundle2 = repository.bundle(for: enGBLocale, referenceBundle: referenceBundle)

        #expect(enUSBundle === enUSBundle2)
        #expect(enGBBundle === enGBBundle2)
    }

    @Test func testBundleForPortuguesePortugalFallsBackToBrazilian() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "pt-PT")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should fall back to "pt" language code, which finds pt-br
        #expect(result != nil)
        #expect(result?.localizations.contains("pt-br") == true)
    }

    @Test func testBundleWithComplexLocaleIdentifier() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module
        let locale = Locale(identifier: "en-US-POSIX")

        let result = repository.bundle(for: locale, referenceBundle: referenceBundle)

        // Should fall back to "en" language code
        #expect(result != nil)
        #expect(result?.localizations.contains("en") == true)
    }
}
