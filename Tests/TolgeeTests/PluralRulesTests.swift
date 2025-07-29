import Foundation
import Testing

@testable import Tolgee

struct PluralRulesTests {

    @Test func testEnglishPluralRules() throws {
        let englishLocale = Locale(identifier: "en")
        let rules = PluralRules.pluralRules(for: englishLocale)

        // English: 1 = one, everything else = other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 5.0) == .other)
        #expect(rules.category(for: 1.5) == .other)  // Decimals are "other"
    }

    @Test func testCzechPluralRules() throws {
        let czechLocale = Locale(identifier: "cs")
        let rules = PluralRules.pluralRules(for: czechLocale)

        // Czech: 1 = one, 2-4 (integers) = few, non-integers = many, 0,5+ = other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .few)
        #expect(rules.category(for: 3.0) == .few)
        #expect(rules.category(for: 4.0) == .few)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 5.0) == .other)
        #expect(rules.category(for: 2.1) == .many)  // Decimals are "many"
        #expect(rules.category(for: 3.5) == .many)  // Decimals are "many"
    }

    @Test func testPolishPluralRules() throws {
        let polishLocale = Locale(identifier: "pl")
        let rules = PluralRules.pluralRules(for: polishLocale)

        // Polish: 1 = one, 2-4 (except 12-14) = few, etc.
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .few)
        #expect(rules.category(for: 3.0) == .few)
        #expect(rules.category(for: 4.0) == .few)
        #expect(rules.category(for: 12.0) == .many)  // Exception: 12-14 are many
        #expect(rules.category(for: 13.0) == .many)
        #expect(rules.category(for: 14.0) == .many)
        #expect(rules.category(for: 22.0) == .few)  // 22 % 10 = 2, 22 % 100 = 22 (not 12-14)
        #expect(rules.category(for: 5.0) == .many)
        #expect(rules.category(for: 0.0) == .many)
        #expect(rules.category(for: 2.5) == .other)  // Decimals are "other"
    }

    @Test func testRussianPluralRules() throws {
        let russianLocale = Locale(identifier: "ru")
        let rules = PluralRules.pluralRules(for: russianLocale)

        // Russian: similar to Polish but more complex
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 21.0) == .one)  // 21 % 10 = 1, 21 % 100 = 21 (not 11)
        #expect(rules.category(for: 2.0) == .few)
        #expect(rules.category(for: 3.0) == .few)
        #expect(rules.category(for: 4.0) == .few)
        #expect(rules.category(for: 22.0) == .few)
        #expect(rules.category(for: 5.0) == .many)
        #expect(rules.category(for: 11.0) == .many)  // Exception: 11-14 are many
        #expect(rules.category(for: 12.0) == .many)
        #expect(rules.category(for: 0.0) == .many)
        #expect(rules.category(for: 2.5) == .other)  // Decimals are "other"
    }

    @Test func testJapanesePluralRules() throws {
        let japaneseLocale = Locale(identifier: "ja")
        let rules = PluralRules.pluralRules(for: japaneseLocale)

        // Japanese: everything is "other"
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 1.0) == .other)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 5.0) == .other)
        #expect(rules.category(for: 1.5) == .other)
    }

    @Test func testFrenchPluralRules() throws {
        let frenchLocale = Locale(identifier: "fr")
        let rules = PluralRules.pluralRules(for: frenchLocale)

        // French: 0,1 = one, millions = many, everything else = other
        #expect(rules.category(for: 0.0) == .one)
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 1.5) == .one)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 5.0) == .other)
        // Note: Million rules are complex and depend on scientific notation
    }

    @Test func testHebrewPluralRules() throws {
        let hebrewLocale = Locale(identifier: "he")
        let rules = PluralRules.pluralRules(for: hebrewLocale)

        // Hebrew: 1 or decimal (i=0, v!=0) = one, 2 = two, everything else = other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .two)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 3.0) == .other)
        #expect(rules.category(for: 0.5) == .one)  // i=0, v!=0 -> one
    }

    @Test func testDefaultFallback() throws {
        let unknownLocale = Locale(identifier: "xyz")  // Non-existent language
        let rules = PluralRules.pluralRules(for: unknownLocale)

        // Should fallback to English-like rules
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 2.0) == .other)
    }

    @Test func testFinnishPluralRules() throws {
        let finnishLocale = Locale(identifier: "fi")
        let rules = PluralRules.pluralRules(for: finnishLocale)

        // Finnish uses English-like rules: 1 = one, everything else = other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 1.5) == .other)
    }

    @Test func testHindiPluralRules() throws {
        let hindiLocale = Locale(identifier: "hi")
        let rules = PluralRules.pluralRules(for: hindiLocale)

        // Hindi: i=0 or n=1 = one, everything else = other
        #expect(rules.category(for: 0.0) == .one)
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 0.5) == .one)  // i=0
    }

    @Test func testMaltesePluralRules() throws {
        let malteseLocale = Locale(identifier: "mt")
        let rules = PluralRules.pluralRules(for: malteseLocale)

        // Maltese: 1=one, 2=two, 0,3-10=few, 11-19=many, other=other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .two)
        #expect(rules.category(for: 0.0) == .few)
        #expect(rules.category(for: 3.0) == .few)
        #expect(rules.category(for: 10.0) == .few)
        #expect(rules.category(for: 11.0) == .many)
        #expect(rules.category(for: 19.0) == .many)
        #expect(rules.category(for: 20.0) == .other)
    }

    @Test func testIrishPluralRules() throws {
        let irishLocale = Locale(identifier: "ga")
        let rules = PluralRules.pluralRules(for: irishLocale)

        // Irish: 1=one, 2=two, 3-6=few, 7-10=many, other=other
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 2.0) == .two)
        #expect(rules.category(for: 3.0) == .few)
        #expect(rules.category(for: 6.0) == .few)
        #expect(rules.category(for: 7.0) == .many)
        #expect(rules.category(for: 10.0) == .many)
        #expect(rules.category(for: 11.0) == .other)
    }

    @Test func testMacedonianPluralRules() throws {
        let macedonianLocale = Locale(identifier: "mk")
        let rules = PluralRules.pluralRules(for: macedonianLocale)

        // Macedonian: similar to Serbian/Croatian but simpler
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 21.0) == .one)
        #expect(rules.category(for: 0.0) == .other)
        #expect(rules.category(for: 2.0) == .other)
        #expect(rules.category(for: 1.1) == .one)  // f % 10 = 1
    }
}
