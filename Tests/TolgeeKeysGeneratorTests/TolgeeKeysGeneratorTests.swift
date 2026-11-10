import Foundation
import Testing

@testable import TolgeeKeysGeneratorCore

struct TolgeeKeysGeneratorTests {

  let catalog = """
    {
      "sourceLanguage" : "en",
      "strings" : {
        "home.send_money" : {
          "comment" : "Primary button that starts a payment.",
          "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Send money" } } }
        },
        "home.greeting" : {
          "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "Hello, %@" } } }
        },
        "examples.exchange_rate" : {
          "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "1 EUR = %.2f CZK (%lld%%)" } } }
        },
        "examples.files_from" : {
          "localizations" : { "en" : { "stringUnit" : { "state" : "translated", "value" : "%2$lld files from %1$@" } } }
        },
        "examples.days_left" : {
          "localizations" : { "en" : { "variations" : { "plural" : {
            "one" : { "stringUnit" : { "state" : "translated", "value" : "One day left" } },
            "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld days left" } }
          } } } }
        },
        "My name is %@" : {}
      },
      "version" : "1.0"
    }
    """

  func generate(table: String = "Localizable") throws -> String {
    try generateKeys(catalog: Data(catalog.utf8), table: table).code
  }

  func generate(strings: String, table: String = "Localizable") throws -> GeneratedKeys {
    let json = #"{ "sourceLanguage" : "en", "strings" : {"# + strings + #"}, "version" : "1.0" }"#
    return try generateKeys(catalog: Data(json.utf8), table: table)
  }

  func text(_ value: String, language: String = "en") -> String {
    #"{ "localizations" : { "\#(language)" : { "stringUnit" : { "state" : "translated", "value" : "\#(value)" } } } }"#
  }

  @Test func plainKey() throws {
    let code = try generate()
    #expect(code.contains("/// Primary button that starts a payment."))
    #expect(code.contains("static var `homeSendMoney`: TolgeeKey {"))
    #expect(code.contains("TolgeeKey(\"home.send_money\", bundle: tolgeeKeysBundle)"))
  }

  @Test func stringParameter() throws {
    let code = try generate()
    #expect(code.contains("static func `homeGreeting`(_ arg1: String) -> TolgeeKey {"))
    #expect(code.contains("TolgeeKey(\"home.greeting\", arguments: [arg1], bundle: tolgeeKeysBundle)"))
  }

  @Test func numberParametersSkipEscapedPercent() throws {
    let code = try generate()
    #expect(
      code.contains("static func `examplesExchangeRate`(_ arg1: Double, _ arg2: Int) -> TolgeeKey {"))
  }

  @Test func positionalParametersKeepTheirOrder() throws {
    let code = try generate()
    #expect(code.contains("static func `examplesFilesFrom`(_ arg1: String, _ arg2: Int) -> TolgeeKey {"))
  }

  @Test func pluralParametersComeFromAllForms() throws {
    let code = try generate()
    #expect(code.contains("static func `examplesDaysLeft`(_ arg1: Int) -> TolgeeKey {"))
  }

  @Test func keyWithoutLocalizationUsesKeyAsSourceText() throws {
    let code = try generate()
    #expect(code.contains("static func `myNameIs`(_ arg1: String) -> TolgeeKey {"))
  }

  @Test func parametersComeFromOtherLanguagesWhenSourceIsMissing() throws {
    let result = try generate(strings: #""greeting" : \#(text("Hallo %@", language: "de"))"#)
    #expect(result.code.contains("static func `greeting`(_ arg1: String) -> TolgeeKey {"))
  }

  @Test func parametersComeFromDeviceVariations() throws {
    let result = try generate(
      strings: #"""
        "tap_hint" : { "localizations" : { "en" : { "variations" : { "device" : {
          "iphone" : { "stringUnit" : { "state" : "translated", "value" : "Tap to open" } },
          "mac" : { "stringUnit" : { "state" : "translated", "value" : "Click %@ to open" } }
        } } } } }
        """#)
    #expect(result.code.contains("static func `tapHint`(_ arg1: String) -> TolgeeKey {"))
  }

  @Test func conflictingParameterTypesSkipTheKey() throws {
    let result = try generate(
      strings: #""count" : { "localizations" : { "en" : \#(unit("%lld items")), "cs" : \#(unit("%@ položek")) } }"#)
    #expect(!result.code.contains("`count`"))
    #expect(result.warnings.contains { $0.contains("\"count\"") })
  }

  func unit(_ value: String) -> String {
    #"{ "stringUnit" : { "state" : "translated", "value" : "\#(value)" } }"#
  }

  @Test func xcodeSubstitutionsBecomeTypedParameters() throws {
    let result = try generate(
      strings: #"""
        "%@ has %lld items" : { "localizations" : { "en" : {
          "stringUnit" : { "state" : "translated", "value" : "%1$@ has %#@arg2@" },
          "substitutions" : { "arg2" : { "argNum" : 2, "formatSpecifier" : "lld", "variations" : { "plural" : {
            "one" : { "stringUnit" : { "state" : "translated", "value" : "%arg item" } },
            "other" : { "stringUnit" : { "state" : "translated", "value" : "%arg items" } }
          } } } }
        } } }
        """#)
    #expect(result.code.contains("static func `hasItems`(_ arg1: String, _ arg2: Int) -> TolgeeKey {"))
    #expect(result.notes.isEmpty)
  }

  @Test func keysWithMoreThanOnePluralArgumentGetNoMember() throws {
    func plural(_ argNum: Int, _ noun: String) -> String {
      #"{ "argNum" : \#(argNum), "formatSpecifier" : "lld", "variations" : { "plural" : { "#
        + #""one" : \#(unit("%arg \(noun)")), "other" : \#(unit("%arg \(noun)s")) } } }"#
    }
    let result = try generate(
      strings: #""fruit" : { "localizations" : { "en" : { "#
        + #""stringUnit" : { "state" : "translated", "value" : "%#@apples@ and %#@oranges@" }, "#
        + #""substitutions" : { "apples" : \#(plural(1, "apple")), "oranges" : \#(plural(2, "orange")) } } } }, "#
        + #""other" : {}"#)
    #expect(!result.code.contains("`fruit`"))
    #expect(result.code.contains("static var `other`: TolgeeKey {"))
    #expect(result.warnings.isEmpty)
    #expect(
      result.notes == [
        "Key \"fruit\" has no member: it has 2 plural arguments (apples, oranges) and the CDN delivers a single "
          + "plural per key. Use the string key; it is served from the app bundle only."
      ])
    #expect(
      result.code.hasSuffix(
        "}\n\n// Keys without a member, served from the app bundle only:\n// \(result.notes[0])\n"))
  }

  @Test func percentSignInPlainTextIsNotAParameter() throws {
    let result = try generate(
      strings: #""Get 50% off" : {}, "fee" : \#(text("A 3% fee applies to %@")), "Save 20%!" : {}, "all" : \#(text("100%"))"#)
    #expect(result.code.contains("static var `get50Off`: TolgeeKey {"))
    #expect(result.code.contains("static func `fee`(_ arg1: String) -> TolgeeKey {"))
    #expect(result.code.contains("static var `save20`: TolgeeKey {"))
    #expect(result.code.contains("static var `all`: TolgeeKey {"))
    #expect(result.warnings.isEmpty)
  }

  @Test func unreadableSpecifiersSkipTheKey() throws {
    let result = try generate(
      strings: #""step" : \#(text("Step %1$1$ld of %2$2$ld")), "letter" : \#(text("%y items")), "ok" : \#(text("%1$@ of %2$@"))"#)
    #expect(!result.code.contains("`step`"))
    #expect(!result.code.contains("`letter`"))
    #expect(result.code.contains("static func `ok`(_ arg1: String, _ arg2: String) -> TolgeeKey {"))
    #expect(result.warnings.count == 2)
    #expect(result.warnings.contains("Key \"step\" skipped: %1$1$ld can't be read as a format specifier."))
  }

  @Test func integerTypesIgnoreTheLengthModifier() throws {
    let result = try generate(strings: #""sizes" : \#(text("%d %lld %u %lu %ld %i"))"#)
    #expect(
      result.code.contains(
        "static func `sizes`(_ arg1: Int, _ arg2: Int, _ arg3: UInt, _ arg4: UInt, _ arg5: Int, _ arg6: Int) -> TolgeeKey {"))
  }

  @Test func differentIntegerLengthsAcrossLanguagesAreOneKey() throws {
    let result = try generate(
      strings: #""count" : { "localizations" : { "en" : \#(unit("%lld items")), "cs" : \#(unit("%d položek")) } }"#)
    #expect(result.code.contains("static func `count`(_ arg1: Int) -> TolgeeKey {"))
    #expect(result.warnings.isEmpty)
  }

  @Test func unsafeSpecifiersSkipTheKey() throws {
    let result = try generate(
      strings: #""c_string" : \#(text("Hi %s")), "width" : \#(text("%*d")), "zero" : \#(text("Item %0$@"))"#)
    #expect(!result.code.contains("static"))
    #expect(result.warnings.count == 3)
  }

  @Test func namesAreCamelCase() throws {
    #expect(identifier(for: "home.send_money") == "homeSendMoney")
    #expect(identifier(for: "HOME_TITLE") == "homeTitle")
    #expect(identifier(for: "settings.SAVE_BUTTON") == "settingsSaveButton")
    #expect(identifier(for: "URLPath") == "urlPath")
    #expect(identifier(for: "%lld items") == "items")
    #expect(identifier(for: "Price: %.2f") == "price")
    #expect(identifier(for: "3d_secure") == "_3dSecure")
  }

  @Test func apostrophesJoinWords() throws {
    #expect(identifier(for: "Don't stop") == "dontStop")
    #expect(identifier(for: "What\u{2019}s new") == "whatsNew")
    #expect(identifier(for: "it's %lld o'clock") == "itsOclock")
    #expect(identifier(for: "'quoted'") == "quoted")
  }

  @Test func collidingNamesStopGeneration() throws {
    #expect(
      problems(#""home.title" : {}, "home_title" : {}, "other" : {}"#) == [
        "Keys \"home.title\", \"home_title\" would all generate `homeTitle`. Rename all but one of them, or "
          + "set \"generatesSymbol\" : false on the ones that need no member."
      ])
  }

  @Test func keysWithoutLettersOrDigitsStopGeneration() throws {
    #expect(
      problems(#""!!!" : {}, "ok" : {}"#) == [
        "Key \"!!!\" has no letters or digits to name a member by. Rename it, or set \"generatesSymbol\" : false on it in the catalog."
      ])
  }

  @Test func everyProblemIsReportedInOneRun() throws {
    let problems = problems(#""!!!" : {}, "home.title" : {}, "home_title" : {}, "key" : {}"#) ?? []
    #expect(problems.count == 3)
    #expect(problems.contains { $0.hasPrefix("Key \"!!!\"") })
    #expect(problems.contains { $0.hasPrefix("Key \"key\"") })
    #expect(problems.contains { $0.hasPrefix("Keys \"home.title\", \"home_title\"") })
  }

  @Test func generatesSymbolFalseExcludesTheKey() throws {
    let result = try generate(
      strings: #"""
        "home.title" : { "generatesSymbol" : false },
        "home_title" : {},
        "!!!" : { "generatesSymbol" : false },
        "c_string" : { "generatesSymbol" : false, "localizations" : { "en" : \#(unit("Hi %s")) } },
        "kept" : { "generatesSymbol" : true }
        """#)
    #expect(result.code.contains("/// Key \"home_title\"\n    static var `homeTitle`: TolgeeKey {"))
    #expect(!result.code.contains("home.title"))
    #expect(!result.code.contains("cString"))
    #expect(result.code.contains("`kept`"))
    #expect(result.warnings.isEmpty)
  }

  /// The problems a catalog stops generation with, or nil when it generates.
  func problems(_ strings: String) -> [String]? {
    do {
      _ = try generate(strings: strings)
      return nil
    } catch let error as GeneratorError {
      return error.problems
    } catch {
      return nil
    }
  }

  @Test func sameNameWithDifferentParametersIsAnOverload() throws {
    let result = try generate(strings: #""Delete" : {}, "Delete %@?" : {}"#)
    #expect(result.code.contains("static var `delete`: TolgeeKey {"))
    #expect(result.code.contains("static func `delete`(_ arg1: String) -> TolgeeKey {"))
    #expect(result.warnings.isEmpty)
  }

  @Test func namesOfTolgeeKeyPropertiesStopGeneration() throws {
    let problems = problems(#""Key" : {}, "table" : {}, "arguments" : {}, "bundle" : {}"#) ?? []
    #expect(problems.count == 4)
    #expect(
      problems.contains(
        "Key \"Key\" would generate `key`, which TolgeeKey already has. Rename it, or set \"generatesSymbol\" : false on it in the catalog."
      ))
  }

  @Test func keysAndCommentsAreEscaped() throws {
    let result = try generate(
      strings: #""Welcome back!\nTap\tto \"continue\"" : { "comment" : "First line\r\nsecond line\rthird" }"#)
    #expect(result.code.contains(#"TolgeeKey("Welcome back!\nTap\tto \"continue\"", bundle: tolgeeKeysBundle)"#))
    #expect(result.code.contains("    /// First line\n    /// second line\n    /// third\n"))
    #expect(!result.code.contains("\r"))
    #expect(!result.code.contains("\t"))
  }

  @Test func otherTablesAreNested() throws {
    let code = try generate(table: "Payments")
    #expect(code.contains("    enum Payments {\n"))
    #expect(code.contains("TolgeeKey(\"home.send_money\", table: \"Payments\", bundle: tolgeeKeysBundle)"))
  }

  @Test func generatedCodeUsesTheCatalogBundle() throws {
    let code = try generate()
    #expect(code.contains("private let tolgeeKeysBundle = Bundle.module"))
    #expect(code.contains("private let tolgeeKeysBundle = Bundle(for: TolgeeKeysBundleToken.self)"))
  }
}
