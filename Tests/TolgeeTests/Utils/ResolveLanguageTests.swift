import Foundation
import Testing

@testable import Tolgee

struct ResolveLanguageTests {

    @Test func testResolveLanguageExactMatch() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "en")

        let result = resolveLanguage(for: locale, in: bundle)

        #expect(result == "en")
    }

    @Test func testResolveLanguageWithRegion() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "en-US")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should match "en" as the base language
        #expect(result == "en")
    }

    @Test func testResolveLanguageRegionalVariant() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "en-GB")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should fall back to "en"
        #expect(result == "en")
    }

    @Test func testResolveLanguageCzech() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "cs")

        let result = resolveLanguage(for: locale, in: bundle)

        #expect(result == "cs")
    }

    @Test func testResolveLanguageCzechWithRegion() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "cs-CZ")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should match "cs" as the base language
        #expect(result == "cs")
    }

    @Test func testResolveLanguageUnsupportedLanguage() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "sp")

        let result = resolveLanguage(for: locale, in: bundle)

        #expect(result == "en")
    }

    @Test func testResolveLanguageNonStandardIdentifier() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "en_US")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should still resolve to "en"
        #expect(result == "en")
    }

    @Test func testResolveLanguageExcludesBase() throws {
        let bundle = Bundle.module

        // Verify that Base localization is not returned
        // Test with various locales to ensure none resolve to "base"
        let locales = [
            Locale(identifier: "en"),
            Locale(identifier: "cs"),
            Locale(identifier: "fr"),
        ]

        for locale in locales {
            let result = resolveLanguage(for: locale, in: bundle)
            #expect(result != "base")
        }
    }

    @Test func testResolveLanguagePortugueseBaseResolvesToBrazilian() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "pt")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should resolve to "pt-br" since that's the only Portuguese variant available
        #expect(result == "pt-br")
    }

    @Test func testResolveLanguagePortuguesePortugalResolvesToBrazilian() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "pt-PT")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should fall back to "pt-br" since pt-PT is not available
        #expect(result == "pt-br")
    }

    @Test func testResolveLanguagePortugueseBrazilExactMatch() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "pt-BR")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should match exactly to "pt-br"
        #expect(result == "pt-br")
    }

    @Test func testResolveLanguagePortugueseBrazilWithUnderscore() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "pt_BR")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should resolve to "pt-br" even with underscore separator
        #expect(result == "pt-br")
    }

    @Test func testResolveLanguageChineseBaseResolvesToSimplified() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "zh")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should resolve to "zh-hans" since that's the only Chinese variant available
        #expect(result == "zh-hans")
    }

    @Test func testResolveLanguageChineseSimplifiedExactMatch() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "zh-Hans")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should match exactly to "zh-hans"
        #expect(result == "zh-hans")
    }

    @Test func testResolveLanguageChineseSimplifiedWithUnderscore() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "zh_Hans")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should resolve to "zh-hans" even with underscore separator
        #expect(result == "zh-hans")
    }

    @Test func testResolveLanguageChineseTraditionalFallsBackToEnglish() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "zh-Hant")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should fall back to "en" since zh-Hant is not available
        #expect(result == "en")
    }

    @Test func testResolveLanguageChineseTraditionalWithUnderscoreFallsBackToEnglish() throws {
        let bundle = Bundle.module
        let locale = Locale(identifier: "zh_Hant")

        let result = resolveLanguage(for: locale, in: bundle)

        // Should fall back to "en" since zh-Hant is not available
        #expect(result == "en")
    }
}
