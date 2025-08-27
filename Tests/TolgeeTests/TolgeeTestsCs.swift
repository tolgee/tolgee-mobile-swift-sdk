import Foundation
import Testing

@testable import Tolgee

@MainActor
final class TestContext {
  let tolgee: Tolgee
  let cache: MockCache
  let urlSession: MockURLSession

  init() {
    self.cache = MockCache()
    self.urlSession = MockURLSession()
    self.tolgee = Tolgee(
      urlSession: urlSession,
      cache: cache,
      appVersionSignature: "1.0.0-1"
    )
  }
}

@MainActor
struct TolgeeTestsCs {

  // Czech test data with Apple-style complex plural forms
  let testTranslationsJSON = """
    {
      "Hello, world!": "Ahoj, světe!",
      "I have %lld apples": {
        "variations": {
          "plural": {
            "one": "Mám %lld jablko",
            "few": "Mám %lld jablka",
            "other": "Mám %lld jablek",
            "many": "Mám %lld jablek"
          }
        }
      },
      "My name is %@": "Jmenuji se %@",
      "Redraw": "Překreslit"
    }
    """

  let czechLocale = Locale(identifier: "cs_CZ")

  @Test func testLoadCzechTranslationsFromJSON() async throws {

    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "cs")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    if #available(macOS 15.4, *) {

      // Test basic Czech translation without arguments
      let greeting = tolgee.translate("Hello, world!", locale: czechLocale)
      #expect(greeting == "Ahoj, světe!")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testCzechSimplePlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "cs")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    if #available(macOS 15.4, *) {

      // Test Czech name replacement
      let nameTranslation = tolgee.translate("My name is %@", "Jan", locale: czechLocale)
      #expect(nameTranslation == "Jmenuji se Jan")

      let anotherName = tolgee.translate("My name is %@", "Marie", locale: czechLocale)
      #expect(anotherName == "Jmenuji se Marie")

    } else {
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testCzechPluralFormsWithHashReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "cs")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

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
      #expect(Bool(false))  // Skip this test on older versions
    }
  }

  @Test func testCzechMissingTranslationFallback() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, language: "cs")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    // Test with a key that doesn't exist (should fallback to NSLocalizedString)
    let missingKey = tolgee.translate("nonexistent.key")
    #expect(missingKey == "nonexistent.key")
  }
}
