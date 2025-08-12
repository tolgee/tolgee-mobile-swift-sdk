import Foundation
import Testing

@testable import Tolgee

@MainActor
struct TolgeeTestsEn {

  // English test data with Apple-style plural forms
  let testTranslationsJSON = """
    {
      "Hello, world!": "Hello, world!",
      "I have %lld apples": {
        "variations": {
          "plural": {
            "one": "I have %lld apple",
            "other": "I have %lld apples"
          }
        }
      },
      "My name is %@": "My name is %@",
      "Redraw": "Redraw"
    }
    """

  let englishLocale = Locale(identifier: "en_US")

  @Test func testLoadEnglishTranslationsFromJSON() throws {

    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    try tolgee.loadTranslations(from: testTranslationsJSON)

    if #available(macOS 15.4, *) {

      // Test basic English translation without arguments
      let greeting = tolgee.translate("Hello, world!", locale: englishLocale)
      #expect(greeting == "Hello, world!")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testEnglishSimplePlaceholderReplacement() throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")
    try tolgee.loadTranslations(from: testTranslationsJSON)

    if #available(macOS 15.4, *) {

      // Test English name replacement
      let nameTranslation = tolgee.translate("My name is %@", "John", locale: englishLocale)
      #expect(nameTranslation == "My name is John")

      let anotherName = tolgee.translate("My name is %@", "Alice", locale: englishLocale)
      #expect(anotherName == "My name is Alice")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testEnglishPluralFormsWithHashReplacement() throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")
    try tolgee.loadTranslations(from: testTranslationsJSON)

    if #available(macOS 15.4, *) {

      // Test English singular form (1)
      let oneApple = tolgee.translate("I have %lld apples", 1, locale: englishLocale)
      #expect(oneApple == "I have 1 apple")

      // Test English plural form (2+)
      let multipleApples = tolgee.translate("I have %lld apples", 5, locale: englishLocale)
      #expect(multipleApples == "I have 5 apples")

      // Test zero (should use plural/other)
      let zeroApples = tolgee.translate("I have %lld apples", 0, locale: englishLocale)
      #expect(zeroApples == "I have 0 apples")

      // Test edge case: 2 apples
      let twoApples = tolgee.translate("I have %lld apples", 2, locale: englishLocale)
      #expect(twoApples == "I have 2 apples")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testEnglishMissingTranslationFallback() throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")
    try tolgee.loadTranslations(from: testTranslationsJSON)

    // Test with a key that doesn't exist (should fallback to NSLocalizedString)
    let missingKey = tolgee.translate("nonexistent.key")
    #expect(missingKey == "nonexistent.key")
  }
}
