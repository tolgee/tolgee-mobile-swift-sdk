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

    // MARK: - Table Tests for Languages with Similar Rules

    @Test func testOtherOnlyLanguages() throws {
        // Languages that have only "other" category for all numbers
        let otherOnlyLanguages = ["ja", "ko", "zh", "th", "vi", "id", "ms", "my", "km", "lo"]
        let testNumbers = [0.0, 1.0, 2.0, 5.0, 1.5, 11.0, 21.0, 100.0]

        for languageCode in otherOnlyLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            for number in testNumbers {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testEnglishLikeLanguages() throws {
        // Languages that follow English-like rules: 1 = one, everything else = other
        let englishLikeLanguages = [
            "en", "de", "nl", "sv", "da", "no", "nb", "nn", "fi", "et", "eu", "gl",
            "el", "bg", "sq", "ta", "te", "ml", "mr", "ur", "ne", "sw", "af",
        ]

        for languageCode in englishLikeLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // 1.0 should be "one"
            #expect(
                rules.category(for: 1.0) == .one,
                "Language \(languageCode) should return .one for 1.0"
            )

            // Everything else should be "other"
            let otherNumbers = [0.0, 2.0, 5.0, 1.5, 11.0, 21.0, 100.0]
            for number in otherNumbers {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testSimpleOneOtherLanguages() throws {
        // Languages that use simple n=1 rule (not requiring v=0)
        let simpleOneOtherLanguages = ["hu", "tr", "az", "ka", "hy", "is"]

        for languageCode in simpleOneOtherLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // 1.0 should be "one"
            #expect(
                rules.category(for: 1.0) == .one,
                "Language \(languageCode) should return .one for 1.0"
            )

            // Everything else should be "other"
            let otherNumbers = [0.0, 2.0, 5.0, 1.5, 11.0, 21.0, 100.0]
            for number in otherNumbers {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testIndicLanguages() throws {
        // Languages that use "i=0 or n=1" rule
        let indicLanguages = ["hi", "bn", "gu", "kn", "fa"]

        for languageCode in indicLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // Should be "one": 0.0, 1.0, 0.5 (i=0)
            let oneNumbers = [0.0, 1.0, 0.5, 0.1, 0.9]
            for number in oneNumbers {
                #expect(
                    rules.category(for: number) == .one,
                    "Language \(languageCode) should return .one for \(number)"
                )
            }

            // Should be "other": 2.0, 5.0, 1.5, etc.
            let otherNumbers = [2.0, 5.0, 1.5, 11.0, 21.0, 100.0]
            for number in otherNumbers {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testRomanManyLanguages() throws {
        // Romance languages with "many" category for millions
        let romanManyLanguages = ["fr", "es", "pt", "it", "ca"]

        for languageCode in romanManyLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // Basic tests for common numbers
            if languageCode == "fr" || languageCode == "pt" {
                // French/Portuguese: 0,1 = one
                #expect(
                    rules.category(for: 0.0) == .one,
                    "Language \(languageCode) should return .one for 0.0"
                )
                #expect(
                    rules.category(for: 1.0) == .one,
                    "Language \(languageCode) should return .one for 1.0"
                )
            } else if languageCode == "es" {
                // Spanish: n=1 = one
                #expect(
                    rules.category(for: 1.0) == .one,
                    "Language \(languageCode) should return .one for 1.0"
                )
                #expect(
                    rules.category(for: 0.0) == .other,
                    "Language \(languageCode) should return .other for 0.0"
                )
            } else if languageCode == "it" || languageCode == "ca" {
                // Italian/Catalan: i=1 and v=0 = one
                #expect(
                    rules.category(for: 1.0) == .one,
                    "Language \(languageCode) should return .one for 1.0"
                )
                #expect(
                    rules.category(for: 1.5) == .other,
                    "Language \(languageCode) should return .other for 1.5"
                )
            }

            // Common "other" cases
            #expect(
                rules.category(for: 2.0) == .other,
                "Language \(languageCode) should return .other for 2.0"
            )
        }
    }

    @Test func testSlavicFourCategoryLanguages() throws {
        // Slavic languages with one/few/many/other categories
        let slavicLanguages = ["cs", "sk"]

        for languageCode in slavicLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // one: 1
            #expect(
                rules.category(for: 1.0) == .one,
                "Language \(languageCode) should return .one for 1.0"
            )

            // few: 2-4 (integers only)
            for number in [2.0, 3.0, 4.0] {
                #expect(
                    rules.category(for: number) == .few,
                    "Language \(languageCode) should return .few for \(number)"
                )
            }

            // many: decimals
            for number in [1.5, 2.1, 3.7] {
                #expect(
                    rules.category(for: number) == .many,
                    "Language \(languageCode) should return .many for \(number)"
                )
            }

            // other: 0, 5+
            for number in [0.0, 5.0, 11.0, 100.0] {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testComplexSlavicLanguages() throws {
        // Russian/Ukrainian with complex modulo rules
        let complexSlavicLanguages = ["ru", "uk"]

        for languageCode in complexSlavicLanguages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // one: 1, 21, 31, 41, etc. (ending in 1, except 11)
            for number in [1.0, 21.0, 31.0, 41.0, 101.0] {
                #expect(
                    rules.category(for: number) == .one,
                    "Language \(languageCode) should return .one for \(number)"
                )
            }

            // few: 2-4, 22-24, 32-34, etc. (ending in 2-4, except 12-14)
            for number in [2.0, 3.0, 4.0, 22.0, 23.0, 24.0, 32.0] {
                #expect(
                    rules.category(for: number) == .few,
                    "Language \(languageCode) should return .few for \(number)"
                )
            }

            // many: 0, 5-20, 25-30, etc. (ending in 0,5-9 or 11-14)
            for number in [0.0, 5.0, 11.0, 12.0, 13.0, 14.0, 20.0, 25.0] {
                #expect(
                    rules.category(for: number) == .many,
                    "Language \(languageCode) should return .many for \(number)"
                )
            }

            // other: decimals
            for number in [1.5, 2.1, 3.7] {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    // MARK: - Individual Language Tests for Complex Rules

    @Test func testPolishDetailedRules() throws {
        let polishLocale = Locale(identifier: "pl")
        let rules = PluralRules.pluralRules(for: polishLocale)

        // one: 1
        #expect(rules.category(for: 1.0) == .one)

        // few: 2-4, 22-24, 32-34, etc. (ending in 2-4, except 12-14)
        let fewNumbers = [2.0, 3.0, 4.0, 22.0, 23.0, 24.0, 32.0, 33.0, 34.0, 102.0, 103.0, 104.0]
        for number in fewNumbers {
            #expect(rules.category(for: number) == .few, "Polish should return .few for \(number)")
        }

        // many: exceptions 12-14 and others
        let manyNumbers = [
            0.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 20.0, 25.0, 100.0,
        ]
        for number in manyNumbers {
            #expect(
                rules.category(for: number) == .many, "Polish should return .many for \(number)")
        }

        // other: decimals
        let otherNumbers = [1.5, 2.1, 3.7, 12.5]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Polish should return .other for \(number)")
        }
    }

    @Test func testBelarusianRules() throws {
        let belarusianLocale = Locale(identifier: "be")
        let rules = PluralRules.pluralRules(for: belarusianLocale)

        // one: 1, 21, 31, etc. (n % 10 = 1 and n % 100 != 11)
        let oneNumbers = [1.0, 21.0, 31.0, 41.0, 51.0, 61.0, 71.0, 81.0, 101.0]
        for number in oneNumbers {
            #expect(
                rules.category(for: number) == .one, "Belarusian should return .one for \(number)")
        }

        // few: 2-4, 22-24, etc. (n % 10 = 2-4 and n % 100 != 12-14)
        let fewNumbers = [2.0, 3.0, 4.0, 22.0, 23.0, 24.0, 32.0, 33.0, 34.0]
        for number in fewNumbers {
            #expect(
                rules.category(for: number) == .few, "Belarusian should return .few for \(number)")
        }

        // many: 0, 5-20, 25-30, etc.
        let manyNumbers = [0.0, 5.0, 6.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 20.0, 25.0, 100.0]
        for number in manyNumbers {
            #expect(
                rules.category(for: number) == .many, "Belarusian should return .many for \(number)"
            )
        }
    }

    @Test func testCroatianSerbianBosnianRules() throws {
        let languages = ["hr", "sr", "bs"]

        for languageCode in languages {
            let locale = Locale(identifier: languageCode)
            let rules = PluralRules.pluralRules(for: locale)

            // one: 1, 21, 31, etc. and 1.1, 2.1, etc.
            let oneNumbers = [1.0, 21.0, 31.0, 1.1, 2.1, 3.1]
            for number in oneNumbers {
                #expect(
                    rules.category(for: number) == .one,
                    "Language \(languageCode) should return .one for \(number)"
                )
            }

            // few: 2-4, 22-24, etc. and 1.2-1.4, 2.2-2.4, etc.
            let fewNumbers = [2.0, 3.0, 4.0, 22.0, 23.0, 24.0, 1.2, 1.3, 1.4, 2.2, 2.3, 2.4]
            for number in fewNumbers {
                #expect(
                    rules.category(for: number) == .few,
                    "Language \(languageCode) should return .few for \(number)"
                )
            }

            // other: everything else
            let otherNumbers = [0.0, 5.0, 11.0, 12.0, 20.0, 1.5, 2.5]
            for number in otherNumbers {
                #expect(
                    rules.category(for: number) == .other,
                    "Language \(languageCode) should return .other for \(number)"
                )
            }
        }
    }

    @Test func testSlovenianRules() throws {
        let slovenianLocale = Locale(identifier: "sl")
        let rules = PluralRules.pluralRules(for: slovenianLocale)

        // one: 1, 101, 201, etc. (v=0 and i%100=1)
        let oneNumbers = [1.0, 101.0, 201.0, 301.0]
        for number in oneNumbers {
            #expect(
                rules.category(for: number) == .one, "Slovenian should return .one for \(number)")
        }

        // two: 2, 102, 202, etc. (v=0 and i%100=2)
        let twoNumbers = [2.0, 102.0, 202.0, 302.0]
        for number in twoNumbers {
            #expect(
                rules.category(for: number) == .two, "Slovenian should return .two for \(number)")
        }

        // few: 3-4, 103-104, etc. and decimals
        let fewNumbers = [3.0, 4.0, 103.0, 104.0, 203.0, 204.0, 1.5, 2.1, 0.5]
        for number in fewNumbers {
            #expect(
                rules.category(for: number) == .few, "Slovenian should return .few for \(number)")
        }

        // other: 0, 5+, etc.
        let otherNumbers = [0.0, 5.0, 11.0, 100.0, 105.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other,
                "Slovenian should return .other for \(number)")
        }
    }

    @Test func testLithuanianRules() throws {
        let lithuanianLocale = Locale(identifier: "lt")
        let rules = PluralRules.pluralRules(for: lithuanianLocale)

        // one: 1, 21, 31, etc. and their decimals like 1.1, 21.1 (n%10=1 and n%100!=11-19)
        let oneNumbers = [1.0, 21.0, 31.0, 41.0, 101.0, 1.1, 21.1, 31.5]
        for number in oneNumbers {
            #expect(
                rules.category(for: number) == .one, "Lithuanian should return .one for \(number)")
        }

        // few: 2-9, 22-29, etc. and their decimals like 2.5, 23.7 (n%10=2-9 and n%100!=11-19)
        let fewNumbers = [2.0, 3.0, 9.0, 22.0, 23.0, 29.0, 102.0, 2.5, 3.7, 22.1]
        for number in fewNumbers {
            #expect(
                rules.category(for: number) == .few, "Lithuanian should return .few for \(number)")
        }

        // many: decimals that don't match above patterns (f != 0 and not covered by one/few)
        let manyNumbers = [0.5, 10.1, 11.1, 20.1]
        for number in manyNumbers {
            #expect(
                rules.category(for: number) == .many, "Lithuanian should return .many for \(number)"
            )
        }

        // other: 0, 10-20, 30, etc. (integers that don't match one/few rules)
        let otherNumbers = [0.0, 10.0, 11.0, 15.0, 20.0, 30.0, 100.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other,
                "Lithuanian should return .other for \(number)")
        }
    }

    @Test func testLatvianRules() throws {
        let latvianLocale = Locale(identifier: "lv")
        let rules = PluralRules.pluralRules(for: latvianLocale)

        // zero: 0, 10, 11-19, 20, 30, etc. (n%10=0 or n%100=11-19)
        let zeroNumbers = [0.0, 10.0, 11.0, 12.0, 19.0, 20.0, 30.0, 100.0]
        for number in zeroNumbers {
            #expect(
                rules.category(for: number) == .zero, "Latvian should return .zero for \(number)")
        }

        // one: 1, 21, 31, etc. (n%10=1 and n%100!=11)
        let oneNumbers = [1.0, 21.0, 31.0, 41.0, 101.0]
        for number in oneNumbers {
            #expect(rules.category(for: number) == .one, "Latvian should return .one for \(number)")
        }

        // other: 2-9, 22-29, etc.
        let otherNumbers = [2.0, 3.0, 9.0, 22.0, 23.0, 29.0, 102.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Latvian should return .other for \(number)")
        }
    }

    @Test func testArabicRules() throws {
        let arabicLocale = Locale(identifier: "ar")
        let rules = PluralRules.pluralRules(for: arabicLocale)

        // zero: 0
        #expect(rules.category(for: 0.0) == .zero)

        // one: 1
        #expect(rules.category(for: 1.0) == .one)

        // two: 2
        #expect(rules.category(for: 2.0) == .two)

        // few: 3-10, 103-110, etc. (n%100=3-10)
        let fewNumbers = [3.0, 4.0, 10.0, 103.0, 104.0, 110.0]
        for number in fewNumbers {
            #expect(rules.category(for: number) == .few, "Arabic should return .few for \(number)")
        }

        // many: 11-99, 111-199, etc. (n%100=11-99)
        let manyNumbers = [11.0, 50.0, 99.0, 111.0, 150.0, 199.0]
        for number in manyNumbers {
            #expect(
                rules.category(for: number) == .many, "Arabic should return .many for \(number)")
        }

        // other: 100-102, 200+, decimals
        let otherNumbers = [100.0, 101.0, 102.0, 200.0, 300.0, 1.5, 2.1]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Arabic should return .other for \(number)")
        }
    }

    @Test func testWelshRules() throws {
        let welshLocale = Locale(identifier: "cy")
        let rules = PluralRules.pluralRules(for: welshLocale)

        // zero: 0
        #expect(rules.category(for: 0.0) == .zero)

        // one: 1
        #expect(rules.category(for: 1.0) == .one)

        // two: 2
        #expect(rules.category(for: 2.0) == .two)

        // few: 3
        #expect(rules.category(for: 3.0) == .few)

        // many: 6
        #expect(rules.category(for: 6.0) == .many)

        // other: everything else
        let otherNumbers = [4.0, 5.0, 7.0, 8.0, 10.0, 1.5]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Welsh should return .other for \(number)")
        }
    }

    @Test func testRomanianRules() throws {
        let romanianLocale = Locale(identifier: "ro")
        let rules = PluralRules.pluralRules(for: romanianLocale)

        // one: 1
        #expect(rules.category(for: 1.0) == .one)

        // few: 0, 2-19, 101-119, decimals
        let fewNumbers = [0.0, 2.0, 10.0, 19.0, 101.0, 110.0, 119.0, 1.5, 2.1]
        for number in fewNumbers {
            #expect(
                rules.category(for: number) == .few, "Romanian should return .few for \(number)")
        }

        // other: 20+, 100, 120+
        let otherNumbers = [20.0, 50.0, 100.0, 120.0, 200.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Romanian should return .other for \(number)"
            )
        }
    }

    @Test func testScottishGaelicRules() throws {
        let scottishGaelicLocale = Locale(identifier: "gd")
        let rules = PluralRules.pluralRules(for: scottishGaelicLocale)

        // one: 1, 11
        #expect(rules.category(for: 1.0) == .one)
        #expect(rules.category(for: 11.0) == .one)

        // two: 2, 12
        #expect(rules.category(for: 2.0) == .two)
        #expect(rules.category(for: 12.0) == .two)

        // few: 3-10, 13-19
        let fewNumbers = [3.0, 4.0, 10.0, 13.0, 14.0, 19.0]
        for number in fewNumbers {
            #expect(
                rules.category(for: number) == .few,
                "Scottish Gaelic should return .few for \(number)")
        }

        // other: 0, 20+
        let otherNumbers = [0.0, 20.0, 21.0, 100.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other,
                "Scottish Gaelic should return .other for \(number)")
        }
    }

    @Test func testBretonRules() throws {
        let bretonLocale = Locale(identifier: "br")
        let rules = PluralRules.pluralRules(for: bretonLocale)

        // one: 1, 21, 31, 41, 51, 61, 81, 101, etc. (n%10=1 and n%100!=11,71,91)
        let oneNumbers = [1.0, 21.0, 31.0, 41.0, 51.0, 61.0, 81.0, 101.0]
        for number in oneNumbers {
            #expect(rules.category(for: number) == .one, "Breton should return .one for \(number)")
        }

        // two: 2, 22, 32, 42, 52, 62, 82, 102, etc. (n%10=2 and n%100!=12,72,92)
        let twoNumbers = [2.0, 22.0, 32.0, 42.0, 52.0, 62.0, 82.0, 102.0]
        for number in twoNumbers {
            #expect(rules.category(for: number) == .two, "Breton should return .two for \(number)")
        }

        // few: 3, 4, 9, 23, 24, 29, etc. (n%10=3,4,9 and n%100 not in ranges)
        let fewNumbers = [3.0, 4.0, 9.0, 23.0, 24.0, 29.0, 103.0]
        for number in fewNumbers {
            #expect(rules.category(for: number) == .few, "Breton should return .few for \(number)")
        }

        // many: 1000000 (millions)
        #expect(rules.category(for: 1_000_000.0) == .many)

        // other: 0, 5-8, 10-20, etc.
        let otherNumbers = [0.0, 5.0, 6.0, 7.0, 8.0, 10.0, 20.0, 100.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Breton should return .other for \(number)")
        }
    }

    @Test func testPunjabiRules() throws {
        let punjabiLocale = Locale(identifier: "pa")
        let rules = PluralRules.pluralRules(for: punjabiLocale)

        // one: 0-1
        let oneNumbers = [0.0, 1.0, 0.5, 0.1, 0.9]
        for number in oneNumbers {
            #expect(rules.category(for: number) == .one, "Punjabi should return .one for \(number)")
        }

        // other: 2+
        let otherNumbers = [2.0, 5.0, 1.5, 11.0, 100.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Punjabi should return .other for \(number)")
        }
    }

    @Test func testSinhalaRules() throws {
        let sinhalaLocale = Locale(identifier: "si")
        let rules = PluralRules.pluralRules(for: sinhalaLocale)

        // one: 0, 1, 0.1 (n=0,1 or i=0 and f=1)
        let oneNumbers = [0.0, 1.0, 0.1]
        for number in oneNumbers {
            #expect(rules.category(for: number) == .one, "Sinhala should return .one for \(number)")
        }

        // other: everything else
        let otherNumbers = [2.0, 5.0, 0.5, 1.5, 11.0, 100.0]
        for number in otherNumbers {
            #expect(
                rules.category(for: number) == .other, "Sinhala should return .other for \(number)")
        }
    }
}
