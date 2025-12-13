import Foundation
import Testing

@testable import Tolgee

@MainActor
struct TolgeeTestsEn {

  // English test data with Apple-style plural forms
  let testTranslationsJSON = """
    {
      "Hello, world!": "[remote] Hello, world!",
      "I have %lld apples": {
        "variations": {
          "plural": {
            "one": "[remote] I have %lld apple",
            "other": "[remote] I have %lld apples"
          }
        }
      },
      "My name is %@": "[remote] My name is %@",
      "Redraw": "Redraw",
      "name_and_num_apples": "[remote] My name is %@ and I have %lld apples"
    }
    """

  let testTranslationsJSONCustomNamespace = """
    {
      "hello_world": "[remote] Hello, world from custom namespace!"
    }
    """

  let englishLocale = Locale(identifier: "en_US")

  @Test func testLoadEnglishTranslationsFromJSON() async throws {

    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale)

    #expect(tolgee.translate("Hello, world!", bundle: .module) == "[local] Hello, world!")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("Hello, world!") == "[remote] Hello, world!")
  }

  @Test func testEnglishSimplePlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale)

    #expect(tolgee.translate("My name is %@", "John", bundle: .module) == "[local] My name is John")
    #expect(
      tolgee.translate("My name is %@", "Alice", bundle: .module) == "[local] My name is Alice")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(
      tolgee.translate("My name is %@", "John", bundle: .module) == "[remote] My name is John")
    #expect(
      tolgee.translate("My name is %@", "Alice", bundle: .module) == "[remote] My name is Alice")
  }

  @Test func testEnglishPluralFormsWithHashReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale)

    #expect(tolgee.translate("I have %lld apples", 1, bundle: .module) == "[local] I have 1 apple")
    #expect(tolgee.translate("I have %lld apples", 5, bundle: .module) == "[local] I have 5 apples")
    #expect(tolgee.translate("I have %lld apples", 0, bundle: .module) == "[local] I have 0 apples")
    #expect(tolgee.translate("I have %lld apples", 2, bundle: .module) == "[local] I have 2 apples")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("I have %lld apples", 1, bundle: .module) == "[remote] I have 1 apple")
    #expect(
      tolgee.translate("I have %lld apples", 5, bundle: .module) == "[remote] I have 5 apples")
    #expect(
      tolgee.translate("I have %lld apples", 0, bundle: .module) == "[remote] I have 0 apples")
    #expect(
      tolgee.translate("I have %lld apples", 2, bundle: .module) == "[remote] I have 2 apples")
  }

  @Test func testEnglishMissingTranslationFallback() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale)

    // Test with a key that doesn't exist (should fallback to NSLocalizedString)
    #expect(tolgee.translate("nonexistent.key", bundle: .module) == "nonexistent.key")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    // Test with a key that doesn't exist (should fallback to NSLocalizedString)
    #expect(tolgee.translate("nonexistent.key", bundle: .module) == "nonexistent.key")
  }

  @Test func testEnglishNameAndNumberPlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale)

    #expect(
      tolgee.translate("name_and_num_apples", "John", 5, bundle: .module)
        == "[local] My name is John and I have 5 apples")
    #expect(
      tolgee.translate("name_and_num_apples", "Alice", 1, bundle: .module)
        == "[local] My name is Alice and I have 1 apples")
    #expect(
      tolgee.translate("name_and_num_apples", "Bob", 0, bundle: .module)
        == "[local] My name is Bob and I have 0 apples")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(
      tolgee.translate("name_and_num_apples", "John", 5, bundle: .module)
        == "[remote] My name is John and I have 5 apples")
    #expect(
      tolgee.translate("name_and_num_apples", "Alice", 1, bundle: .module)
        == "[remote] My name is Alice and I have 1 apples")
    #expect(
      tolgee.translate("name_and_num_apples", "Bob", 0, bundle: .module)
        == "[remote] My name is Bob and I have 0 apples")
  }

  @Test func testLoadEnglishTranslationsFromCustomNamespace() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(
      cdn: URL(string: "https://cdn.example.com")!, locale: englishLocale,
      namespaces: ["namespace"],
      enableDebugLogs: true)

    #expect(
      tolgee.translate("hello_world", table: "namespace", bundle: .module)
        == "[local] Hello, world from custom namespace!")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/en.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/namespace/en.json")!,
      result: .success(Data(testTranslationsJSONCustomNamespace.utf8)))

    await tolgee.remoteFetch()

    #expect(
      tolgee.translate("hello_world", table: "namespace", bundle: .module)
        == "[remote] Hello, world from custom namespace!")
  }
}
