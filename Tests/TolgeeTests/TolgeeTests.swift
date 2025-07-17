import Testing

@testable import Tolgee

@MainActor
struct TolgeeTests {

    // Test data matching the example JSON structure
    let testTranslationsJSON = """
        {
          "Hello, world!": "Hello, world!",
          "I have %lf pears": "{0, plural, one {I have %lf pear} other {I have %lf pears}}",
          "I have %lld apples": "{0, plural, one {I have # apple} other {I have # apples}}",
          "My name is %@": "My name is {0}"
        }
        """

    @Test func testLoadTranslationsFromJSON() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test basic translation without arguments
        let greeting = tolgee.translate("Hello, world!")
        #expect(greeting == "Hello, world!")
    }

    @Test func testSimplePlaceholderReplacement() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test simple placeholder replacement
        let nameTranslation = tolgee.translate("My name is %@", "John")
        #expect(nameTranslation == "My name is John")

        let anotherName = tolgee.translate("My name is %@", "Alice")
        #expect(anotherName == "My name is Alice")
    }

    @Test func testPluralFormsWithHashReplacement() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test singular form
        let oneApple = tolgee.translate("I have %lld apples", 1)
        #expect(oneApple == "I have 1 apple")

        // Test plural form
        let multipleApples = tolgee.translate("I have %lld apples", 5)
        #expect(multipleApples == "I have 5 apples")

        // Test zero (should use plural)
        let zeroApples = tolgee.translate("I have %lld apples", 0)
        #expect(zeroApples == "I have 0 apples")
    }

    @Test func testPluralFormsWithPercentFormatting() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test singular form with double
        let onePear = tolgee.translate("I have %lf pears", 1.0)
        #expect(onePear == "I have 1.0 pear")

        // Test plural form with double
        let multiplePears = tolgee.translate("I have %lf pears", 2.5)
        #expect(multiplePears == "I have 2.5 pears")

        // Test zero (should use plural)
        let zeroPears = tolgee.translate("I have %lf pears", 0.0)
        #expect(zeroPears == "I have 0.0 pears")
    }

    @Test func testFloatArguments() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test with Float type
        let floatValue: Float = 1.0
        let onePearFloat = tolgee.translate("I have %lf pears", floatValue)
        #expect(onePearFloat == "I have 1.0 pear")

        let multipleFloatValue: Float = 3.14
        let multiplePearsFloat = tolgee.translate("I have %lf pears", multipleFloatValue)
        #expect(multiplePearsFloat == "I have 3.14 pears")
    }

    @Test func testNonNumericArgumentsDefaultToPlural() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test with string argument (should default to plural)
        let stringApples = tolgee.translate("I have %lld apples", "many")
        #expect(stringApples == "I have many apples")
    }

    @Test func testTranslationWithoutArguments() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test translation without arguments
        let simpleTranslation = tolgee.translate("Hello, world!")
        #expect(simpleTranslation == "Hello, world!")
    }

    @Test func testMissingTranslationFallback() throws {
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: testTranslationsJSON)

        // Test with a key that doesn't exist (should fallback to NSLocalizedString)
        let missingKey = tolgee.translate("nonexistent.key")
        #expect(missingKey == "nonexistent.key")  // NSLocalizedString returns the key if no translation found
    }

    @Test func testEmptyTranslationsJSON() throws {
        let emptyJSON = "{}"
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: emptyJSON)

        // Should fallback to NSLocalizedString
        let result = tolgee.translate("any.key")
        #expect(result == "any.key")
    }

    @Test func testInvalidJSONThrowsError() throws {
        let invalidJSON = "{ invalid json }"
        let tolgee = Tolgee.shared

        #expect(throws: (any Error).self) {
            try tolgee.loadTranslations(from: invalidJSON)
        }
    }

    @Test func testLoadTranslationsFromData() throws {
        let data = testTranslationsJSON.data(using: .utf8)!
        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: data)

        let result = tolgee.translate("My name is %@", "Test")
        #expect(result == "My name is Test")
    }

    @Test func testComplexPluralScenarios() throws {
        let complexJSON = """
            {
              "items": "{0, plural, one {You have # item} other {You have # items}}"
            }
            """

        let tolgee = Tolgee.shared
        try tolgee.loadTranslations(from: complexJSON)

        // Test edge cases
        let negativeOne = tolgee.translate("items", -1)
        #expect(negativeOne == "You have -1 items")  // Negative numbers should use plural

        let largeNumber = tolgee.translate("items", 1000)
        #expect(largeNumber == "You have 1000 items")
    }
}
