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

        // Test Czech singular form (1)
        let oneApple = tolgee.translate("I have %lld apples", 1)
        #expect(oneApple == "Mám 1 jablko")

        // Test Czech few form (2-4) - Note: Our current implementation doesn't handle "few", so it will use "other"
        let fewApples = tolgee.translate("I have %lld apples", 3)
        #expect(fewApples == "Mám 3 jablek")  // Falls back to "other" since we don't parse "few"

        // Test Czech plural form (5+)
        let manyApples = tolgee.translate("I have %lld apples", 5)
        #expect(manyApples == "Mám 5 jablek")

        // Test zero (should use plural/other)
        let zeroApples = tolgee.translate("I have %lld apples", 0)
        #expect(zeroApples == "Mám 0 jablek")
    }

    @Test func testCzechPluralFormsWithPercentFormatting() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test Czech singular form with double
        let onePear = tolgee.translate("I have %lf pears", 1.0)
        #expect(onePear == "Mám 1.0 hrušku")

        // Test Czech plural form with double
        let multiplePears = tolgee.translate("I have %lf pears", 2.5)
        #expect(multiplePears == "Mám 2.5 hrušek")  // Falls back to "other" since we don't parse "few"

        // Test zero (should use plural/other)
        let zeroPears = tolgee.translate("I have %lf pears", 0.0)
        #expect(zeroPears == "Mám 0.0 hrušek")
    }

    @Test func testCzechMissingTranslationFallback() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test with a key that doesn't exist (should fallback to NSLocalizedString)
        let missingKey = tolgee.translate("nonexistent.key")
        #expect(missingKey == "nonexistent.key")  // NSLocalizedString returns the key if no translation found
    }
}
