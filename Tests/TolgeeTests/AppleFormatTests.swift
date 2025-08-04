import Foundation
import Testing

@testable import Tolgee

@MainActor
struct AppleFormatTests {

    @Test
    @available(iOS 18.4, macOS 15.4, *)
    func testAppleStylePluralFormatWithCzechLocale() throws {
        // Test data with Apple-style JSON format and %%lf bug using Czech translations
        let testTranslationsJSON = """
            {
              "I have %lf pears": {
                "variations": {
                  "plural": {
                    "one": "Mám %%lf hrušku",
                    "few": "Mám %%lf hrušky",
                    "other": "Mám %%lf hrušek"
                  }
                }
              }
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Create Czech locale for testing
        let czechLocale = Locale(identifier: "cs_CZ")

        // Test Czech plural forms with %%lf bug fix
        // Czech: 1 = one, 2-4 = few, 5+ = other
        let result1 = tolgee.translate("I have %lf pears", 1.0, locale: czechLocale)
        #expect(result1 == "Mám 1.0 hrušku")  // one form

        let result2 = tolgee.translate("I have %lf pears", 2.0, locale: czechLocale)
        #expect(result2 == "Mám 2.0 hrušky")  // few form

        let result5 = tolgee.translate("I have %lf pears", 5.0, locale: czechLocale)
        #expect(result5 == "Mám 5.0 hrušek")  // other form
    }

    @Test
    @available(iOS 18.4, macOS 15.4, *)
    func testAppleStyleWithCzechManyForm() throws {
        // Test data with many form showing that all variants are preserved
        let testTranslationsJSON = """
            {
              "I have %lld apples": {
                "variations": {
                  "plural": {
                    "one": "Mám %lld jablko",
                    "few": "Mám %lld jablka",
                    "many": "Mám %lld jablek",
                    "other": "Mám %lld jablek"
                  }
                }
              }
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Create Czech locale for testing
        let czechLocale = Locale(identifier: "cs_CZ")

        // Test Czech plural forms
        let result1 = tolgee.translate("I have %lld apples", 1, locale: czechLocale)
        #expect(result1 == "Mám 1 jablko")  // one

        let result2 = tolgee.translate("I have %lld apples", 2, locale: czechLocale)
        #expect(result2 == "Mám 2 jablka")  // few

        let result5 = tolgee.translate("I have %lld apples", 5, locale: czechLocale)
        #expect(result5 == "Mám 5 jablek")  // other
    }

    @Test
    @available(iOS 18.4, macOS 15.4, *)
    func testMixedStringAndAppleFormatWithCzech() throws {
        // Test mixing simple strings and Apple-style plurals with Czech locale
        let testTranslationsJSON = """
            {
              "Hello, world!": "Ahoj, světe!",
              "I have %lf items": {
                "variations": {
                  "plural": {
                    "one": "Mám %%lf předmět",
                    "few": "Mám %%lf předměty",
                    "other": "Mám %%lf předmětů"
                  }
                }
              }
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Create Czech locale for testing
        let czechLocale = Locale(identifier: "cs_CZ")

        // Simple string should work
        let hello = tolgee.translate("Hello, world!")
        #expect(hello == "Ahoj, světe!")

        // Apple-style plural should work with %%lf fix and Czech locale
        let items1 = tolgee.translate("I have %lf items", 1.0, locale: czechLocale)
        #expect(items1 == "Mám 1.0 předmět")  // one

        let items3 = tolgee.translate("I have %lf items", 3.14, locale: czechLocale)
        #expect(items3 == "Mám 3.14 předměty")  // few

        let items10 = tolgee.translate("I have %lf items", 10.5, locale: czechLocale)
        #expect(items10 == "Mám 10.5 předmětů")  // other
    }

    @Test
    @available(iOS 18.4, macOS 15.4, *)
    func testDoubleLfBugFix() throws {
        // Specifically test the %%lf -> %lf bug fix
        let testTranslationsJSON = """
            {
              "Temperature": {
                "variations": {
                  "plural": {
                    "one": "%%lf stupeň",
                    "few": "%%lf stupně",
                    "other": "%%lf stupňů"
                  }
                }
              }
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Create Czech locale for testing
        let czechLocale = Locale(identifier: "cs_CZ")

        // Verify %%lf is converted to %lf and then to actual values
        let temp1 = tolgee.translate("Temperature", 1.5, locale: czechLocale)
        #expect(temp1 == "1.5 stupeň")  // Should not contain %% anywhere

        let temp3 = tolgee.translate("Temperature", 3.2, locale: czechLocale)
        #expect(temp3 == "3.2 stupně")  // Should not contain %% anywhere

        let temp25 = tolgee.translate("Temperature", 25.0, locale: czechLocale)
        #expect(temp25 == "25.0 stupňů")  // Should not contain %% anywhere
    }

    @Test
    func testAppleStyleBasicFormatting() throws {
        // Test basic Apple-style formatting without locale requirements
        let testTranslationsJSON = """
            {
              "I have %lf items": {
                "variations": {
                  "plural": {
                    "one": "I have %%lf item",
                    "other": "I have %%lf items"
                  }
                }
              }
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test %%lf bug fix with current locale (English)
        let result1 = tolgee.translate("I have %lf items", 1.0)
        #expect(result1 == "I have 1.0 item")  // one form

        let result2 = tolgee.translate("I have %lf items", 2.5)
        #expect(result2 == "I have 2.5 items")  // other form
    }
}
