import Foundation
import Testing

@testable import Tolgee

@MainActor
struct BundleRepositoryTests {

    @Test func testBundleForEnglish() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "en", referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Hello, world!")
    }

    @Test func testBundleForBrazilianPortuguese() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "pt-br", referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Olá, mundo!")
    }

    @Test func testBundleForCzech() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "cs", referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Ahoj, světe!")
    }

    @Test func testBundleForSimplifiedChinese() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "zh-hans", referenceBundle: referenceBundle)

        #expect(result != nil)
        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] 你好，世界！")
    }

    @Test func testBundleReturnsNilForUnsupportedLanguage() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "xyz", referenceBundle: referenceBundle)

        // Should return nil for unsupported language
        #expect(result == nil)
    }

    @Test func testBundleReturnsNilForNonLowercaseLanguage() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let result = repository.bundle(for: "pt-BR", referenceBundle: referenceBundle)

        // Should return nil since language must be lowercase
        #expect(result == nil)
    }

    @Test func testBundleCaching() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let firstResult = repository.bundle(for: "en", referenceBundle: referenceBundle)
        let secondResult = repository.bundle(for: "en", referenceBundle: referenceBundle)

        // Should return the same cached bundle instance
        #expect(firstResult != nil)
        #expect(secondResult != nil)
        #expect(firstResult === secondResult)
    }

    @Test func testBundleCachingWithDifferentLanguages() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let enBundle = repository.bundle(for: "en", referenceBundle: referenceBundle)
        let csBundle = repository.bundle(for: "cs", referenceBundle: referenceBundle)

        // Should return different bundles for different languages
        #expect(enBundle != nil)
        #expect(csBundle != nil)
        #expect(enBundle !== csBundle)
    }

    @Test func testBundleCachingWithRegionalLanguages() throws {
        let repository = BundleRepository()
        let referenceBundle = Bundle.module

        let ptBrBundle = repository.bundle(for: "pt-br", referenceBundle: referenceBundle)
        let zhHansBundle = repository.bundle(for: "zh-hans", referenceBundle: referenceBundle)

        // Both should cache their own lookups
        #expect(ptBrBundle != nil)
        #expect(zhHansBundle != nil)

        // Verify caching works for repeat calls
        let ptBrBundle2 = repository.bundle(for: "pt-br", referenceBundle: referenceBundle)
        let zhHansBundle2 = repository.bundle(for: "zh-hans", referenceBundle: referenceBundle)

        #expect(ptBrBundle === ptBrBundle2)
        #expect(zhHansBundle === zhHansBundle2)
    }

    @Test func testBundleCachingIsPerReferenceBundle() throws {
        let repository = BundleRepository()
        let fixture = try FixtureBundle(localizations: [
            "en": ["Hello, world!": "[fixture] Hello, world!"]
        ])

        let moduleBundle = repository.bundle(for: "en", referenceBundle: .module)
        let fixtureBundle = repository.bundle(for: "en", referenceBundle: fixture.bundle)

        #expect(moduleBundle !== fixtureBundle)
        #expect(
            fixtureBundle?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[fixture] Hello, world!")
        #expect(repository.bundle(for: "en", referenceBundle: .module) === moduleBundle)
    }

    @Test func testBundleNotFoundInAnotherReferenceBundleAfterCaching() throws {
        let repository = BundleRepository()
        let fixture = try FixtureBundle(localizations: [
            "en": ["Hello, world!": "[fixture] Hello, world!"]
        ])

        #expect(repository.bundle(for: "cs", referenceBundle: .module) != nil)
        #expect(repository.bundle(for: "cs", referenceBundle: fixture.bundle) == nil)
    }

    @Test func testLocalizedBundleForLocaleWithRegion() throws {
        let repository = BundleRepository()

        let result = repository.localizedBundle(for: Locale(identifier: "cs_CZ"), in: .module)

        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Ahoj, světe!")
    }

    @Test func testLocalizedBundleFallsBackToAvailableRegionVariant() throws {
        let repository = BundleRepository()

        let result = repository.localizedBundle(for: Locale(identifier: "pt_PT"), in: .module)

        #expect(
            result?.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Olá, mundo!")
    }

    @Test func testLocalizedBundleReturnsNilForUnsupportedLocale() throws {
        let repository = BundleRepository()

        // Asked twice, so the second answer comes from the cached miss.
        #expect(repository.localizedBundle(for: Locale(identifier: "de"), in: .module) == nil)
        #expect(repository.localizedBundle(for: Locale(identifier: "de"), in: .module) == nil)
    }

    @Test func testLocalizedBundleIsResolvedPerReferenceBundle() throws {
        let repository = BundleRepository()
        let fixture = try FixtureBundle(localizations: [
            "en": ["Hello, world!": "[fixture] Hello, world!"],
            "de": ["Hello, world!": "[fixture] Hallo, Welt!"],
        ])
        let german = Locale(identifier: "de")
        let czech = Locale(identifier: "cs")

        #expect(repository.localizedBundle(for: german, in: .module) == nil)
        #expect(
            repository.localizedBundle(for: german, in: fixture.bundle)?
                .localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[fixture] Hallo, Welt!")

        #expect(repository.localizedBundle(for: czech, in: .module) != nil)
        #expect(repository.localizedBundle(for: czech, in: fixture.bundle) == nil)
    }

    @Test func testLocalizedBundleCaching() throws {
        let repository = BundleRepository()
        let locale = Locale(identifier: "cs_CZ")

        let first = repository.localizedBundle(for: locale, in: .module)
        let second = repository.localizedBundle(for: locale, in: .module)

        #expect(first != nil)
        #expect(first === second)
    }
}
