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
      "Hello, world!": "[remote] Ahoj, světe!",
      "I have %lld apples": {
        "variations": {
          "plural": {
            "one": "[remote] Mám %lld jablko",
            "few": "[remote] Mám %lld jablka",
            "other": "[remote] Mám %lld jablek",
            "many": "[remote] Mám %lld jablek"
          }
        }
      },
      "My name is %@": "[remote] Jmenuji se %@",
      "Redraw": "Překreslit"
    }
    """

  let czechLocale = Locale(identifier: "cs_CZ")

  @Test func testLoadCzechTranslationsFromJSON() async throws {

    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: czechLocale)

    #expect(tolgee.translate("Hello, world!", bundle: .module) == "[local] Ahoj, světe!")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("Hello, world!", bundle: .module) == "[remote] Ahoj, světe!")
  }

  @Test func testCzechSimplePlaceholderReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: czechLocale)

    #expect(tolgee.translate("My name is %@", "Jan", bundle: .module) == "[local] Jmenuji se Jan")
    #expect(
      tolgee.translate("My name is %@", "Marie", bundle: .module) == "[local] Jmenuji se Marie")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("My name is %@", "Jan", bundle: .module) == "[remote] Jmenuji se Jan")
    #expect(
      tolgee.translate("My name is %@", "Marie", bundle: .module) == "[remote] Jmenuji se Marie")
  }

  @Test func testCzechPluralFormsWithHashReplacement() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: czechLocale)

    #expect(tolgee.translate("I have %lld apples", 1, bundle: .module) == "[local] Mám 1 jablko")
    #expect(tolgee.translate("I have %lld apples", 3, bundle: .module) == "[local] Mám 3 jablka")
    #expect(tolgee.translate("I have %lld apples", 5, bundle: .module) == "[local] Mám 5 jablek")
    #expect(tolgee.translate("I have %lld apples", 0, bundle: .module) == "[local] Mám 0 jablek")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("I have %lld apples", 1, bundle: .module) == "[remote] Mám 1 jablko")
    #expect(tolgee.translate("I have %lld apples", 3, bundle: .module) == "[remote] Mám 3 jablka")
    #expect(tolgee.translate("I have %lld apples", 5, bundle: .module) == "[remote] Mám 5 jablek")
    #expect(tolgee.translate("I have %lld apples", 0, bundle: .module) == "[remote] Mám 0 jablek")
  }

  @Test func testCzechMissingTranslationFallback() async throws {
    let context = TestContext()
    let tolgee = context.tolgee
    tolgee.initialize(cdn: URL(string: "https://cdn.example.com")!, locale: czechLocale)

    #expect(tolgee.translate("nonexistent.key", bundle: .module) == "nonexistent.key")

    await context.urlSession.setMockResponse(
      for: URL(string: "https://cdn.example.com/cs.json")!,
      result: .success(Data(testTranslationsJSON.utf8)))
    await tolgee.remoteFetch()

    #expect(tolgee.translate("nonexistent.key", bundle: .module) == "nonexistent.key")
  }
}
