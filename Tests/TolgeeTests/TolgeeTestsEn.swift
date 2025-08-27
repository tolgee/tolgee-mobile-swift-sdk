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
      "Redraw": "Redraw",
      "name_and_num_apples": "My name is %@ and I have %lld apples"
    }
    """

  let testTranslationsJSONCustomNamespace = """
    {
      "hello_world": "Hello, world from custom namespace!"
    }
    """

  let englishLocale = Locale(identifier: "en_US")

  @Test func testLoadEnglishTranslationsFromJSON() async throws {

    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    if #available(macOS 15.4, *) {

      // Test basic English translation without arguments
      let greeting = tolgee.translate("Hello, world!", locale: englishLocale)
      #expect(greeting == "Hello, world!")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testEnglishSimplePlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

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

  @Test func testEnglishPluralFormsWithHashReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

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

  @Test func testEnglishMissingTranslationFallback() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    // Test with a key that doesn't exist (should fallback to NSLocalizedString)
    let missingKey = tolgee.translate("nonexistent.key")
    #expect(missingKey == "nonexistent.key")
  }

  @Test func testEnglishNameAndNumberPlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "en")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    if #available(macOS 15.4, *) {

      // Test English name and number replacement
      let nameAndNumber = tolgee.translate("name_and_num_apples", "John", 5, locale: englishLocale)
      #expect(nameAndNumber == "My name is John and I have 5 apples")

      let anotherNameAndNumber = tolgee.translate(
        "name_and_num_apples", "Alice", 1, locale: englishLocale)
      #expect(anotherNameAndNumber == "My name is Alice and I have 1 apples")

      let zeroApples = tolgee.translate("name_and_num_apples", "Bob", 0, locale: englishLocale)
      #expect(zeroApples == "My name is Bob and I have 0 apples")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testLoadEnglishTranslationsFromCustomNamespace() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(
      cdn: URL(string: "https://cdn.example.com")!, language: "en", namespaces: ["namespace"],
      enableDebugLogs: true)

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/namespace/en.json")!,
      result: .success(Data(testTranslationsJSONCustomNamespace.utf8)))

    await tolgee.remoteFetch()

    if #available(macOS 15.4, *) {

      // Test basic English translation from custom namespace
      let greeting = tolgee.translate("hello_world", table: "namespace", locale: englishLocale)
      #expect(greeting == "Hello, world from custom namespace!")

      // Test that keys from the main namespace are not available
      let missingKey = tolgee.translate("Hello, world!", table: "namespace", locale: englishLocale)
      #expect(missingKey == "Hello, world!")  // Should fallback to the key itself

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }
}
