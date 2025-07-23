import Foundation
import Testing

@testable import Tolgee

@MainActor
struct TolgeeTestsCs {

    // Czech test data with complex plural forms
    let testTranslationsJSON = """
        {
          "Hello, world!": "Ahoj světe!",
          "I have %lf pears": "{0, plural, one {Mám %lf hrušku} few {Mám %lf hrušky} other {Mám %lf hrušek} }",
          "I have %lld apples": "{0, plural, one {Mám # jablko} few {Mám # jablka} other {Mám # jablek} }",
          "My name is %@": "Jmenuji se {0}"
        }
        """

    @Test func testLoadCzechTranslationsFromJSON() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test basic Czech translation without arguments
        let greeting = tolgee.translate("Hello, world!")
        #expect(greeting == "Ahoj světe!")
    }

    @Test func testCzechSimplePlaceholderReplacement() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test Czech name replacement
        let nameTranslation = tolgee.translate("My name is %@", "Jan")
        #expect(nameTranslation == "Jmenuji se Jan")

        let anotherName = tolgee.translate("My name is %@", "Marie")
        #expect(anotherName == "Jmenuji se Marie")
    }

    @Test func testCzechPluralFormsWithHashReplacement() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)
        let czechLocale = Locale(identifier: "cs_CZ")

        if #available(macOS 15.4, *) {

            // Test Czech singular form (1)
            let oneApple = tolgee.translate("I have %lld apples", 1, locale: czechLocale)
            #expect(oneApple == "Mám 1 jablko")

            // Test Czech few form (2-4) - Now properly handled!
            let fewApples = tolgee.translate("I have %lld apples", 3, locale: czechLocale)
            #expect(fewApples == "Mám 3 jablka")

            // Test Czech plural form (5+)
            let manyApples = tolgee.translate("I have %lld apples", 5, locale: czechLocale)
            #expect(manyApples == "Mám 5 jablek")

            // Test zero (should use plural/other)
            let zeroApples = tolgee.translate("I have %lld apples", 0, locale: czechLocale)
            #expect(zeroApples == "Mám 0 jablek")

        } else {
            #expect(false)  // Skip this test on older versions
        }
    }

    @Test func testCzechPluralFormsWithPercentFormatting() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)
        let czechLocale = Locale(identifier: "cs_CZ")

        if #available(macOS 15.4, *) {
            // Test Czech singular form with double
            let onePear = tolgee.translate("I have %lf pears", 1.0, locale: czechLocale)
            #expect(onePear == "Mám 1.0 hrušku")

            // Test Czech few form with double
            let fewPears = tolgee.translate("I have %lf pears", 3.0, locale: czechLocale)
            #expect(fewPears == "Mám 3.0 hrušky")

            // Test Czech plural form with double
            let multiplePears = tolgee.translate("I have %lf pears", 2.5, locale: czechLocale)
            #expect(multiplePears == "Mám 2.5 hrušek")  // Non-integer should use "other"

            // Test zero (should use plural/other)
            let zeroPears = tolgee.translate("I have %lf pears", 0.0, locale: czechLocale)
            #expect(zeroPears == "Mám 0.0 hrušek")
        } else {
            #expect(false)  // Skip this test on older versions
        }
    }

    @Test func testCzechMissingTranslationFallback() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test with a key that doesn't exist (should fallback to NSLocalizedString)
        let missingKey = tolgee.translate("nonexistent.key")
        #expect(missingKey == "nonexistent.key")  // NSLocalizedString returns the key if no translation found
    }
}
