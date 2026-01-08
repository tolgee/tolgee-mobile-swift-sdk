import Foundation
import Testing

@testable import Tolgee

struct DoesLocaleMatchLanguageTests {

    @Test func testExactLanguageMatch() throws {
        let locale = Locale(identifier: "en")

        let result = doesLocaleMatchLanguage(locale, language: "en")

        #expect(result == true)
    }

    @Test func testLocaleWithRegionMatchesBaseLanguage() throws {
        let locale = Locale(identifier: "en-US")

        let result = doesLocaleMatchLanguage(locale, language: "en")

        #expect(result == true)
    }

    @Test func testLanguageWithRegionMatchesLocale() throws {
        let locale = Locale(identifier: "en")

        let result = doesLocaleMatchLanguage(locale, language: "en-GB")

        #expect(result == true)
    }

    @Test func testBothWithRegionsMatch() throws {
        let locale = Locale(identifier: "en-US")

        let result = doesLocaleMatchLanguage(locale, language: "en-GB")

        // Both have "en" as base language
        #expect(result == true)
    }

    @Test func testDifferentLanguagesDoNotMatch() throws {
        let locale = Locale(identifier: "en")

        let result = doesLocaleMatchLanguage(locale, language: "cs")

        #expect(result == false)
    }

    @Test func testDifferentLanguagesWithRegionsDoNotMatch() throws {
        let locale = Locale(identifier: "en-US")

        let result = doesLocaleMatchLanguage(locale, language: "cs-CZ")

        #expect(result == false)
    }

    @Test func testUnderscoreSeparatorIsNormalized() throws {
        let locale = Locale(identifier: "en_US")

        let result = doesLocaleMatchLanguage(locale, language: "en-GB")

        // Underscore should be normalized to hyphen
        #expect(result == true)
    }

    @Test func testUnderscoreInLocaleMatchesPlainLanguage() throws {
        let locale = Locale(identifier: "en_US")

        let result = doesLocaleMatchLanguage(locale, language: "en")

        #expect(result == true)
    }

    @Test func testCzechLanguageMatch() throws {
        let locale = Locale(identifier: "cs")

        let result = doesLocaleMatchLanguage(locale, language: "cs")

        #expect(result == true)
    }

    @Test func testCzechWithRegionMatch() throws {
        let locale = Locale(identifier: "cs-CZ")

        let result = doesLocaleMatchLanguage(locale, language: "cs")

        #expect(result == true)
    }

    @Test func testEmptyLanguageString() throws {
        let locale = Locale(identifier: "en")

        let result = doesLocaleMatchLanguage(locale, language: "")

        #expect(result == false)
    }

    @Test func testComplexLocaleIdentifier() throws {
        let locale = Locale(identifier: "en-US-POSIX")

        let result = doesLocaleMatchLanguage(locale, language: "en")

        // Should match on base "en"
        #expect(result == true)
    }
}
