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
}
