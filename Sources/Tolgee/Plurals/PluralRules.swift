import Foundation

public enum PluralCategory {
    case zero
    case one
    case two
    case few
    case many
    case other
}

public struct PluralRules {
    private let languageCode: String

    init(for locale: Locale) {
        self.languageCode = locale.language.languageCode?.identifier ?? "en"
    }

    public func category(for number: Double) -> PluralCategory {
        // Negative numbers typically use "other" form in most languages
        if number < 0 {
            return .other
        }

        let n = number
        let i = Int(abs(number))  // integer part
        let v = numberOfFractionalDigits(number)  // number of visible fraction digits
        let f = fractionalPart(number)  // visible fractional digits as integer
        let _ = trimmedFractionalPart(number)  // fractional digits without trailing zeros

        switch languageCode {
        // Languages with only "other" form
        case "ja", "ko", "zh", "th", "vi", "id", "ms", "my", "km", "lo":
            return .other

        // English and similar languages (one, other)
        case "en", "de", "nl", "sv", "da", "no", "nb", "nn", "fi", "et", "eu", "gl", "el", "bg",
            "sq", "ta", "te", "ml", "mr", "ur", "ne", "sw", "af":
            return englishLikeRules(i: i, v: v)

        // French (one, many, other)
        case "fr":
            return frenchRules(i: i, v: v, e: scientificExponent(number))

        // Spanish (one, many, other)
        case "es":
            return spanishRules(n: n, i: i, v: v, e: scientificExponent(number))

        // Portuguese (one, many, other)
        case "pt":
            return portugueseRules(i: i, v: v, e: scientificExponent(number))

        // Italian and Catalan (one, many, other)
        case "it", "ca":
            return italianRules(i: i, v: v, e: scientificExponent(number))

        // Czech and Slovak (one, few, many, other)
        case "cs", "sk":
            return czechSlovakRules(i: i, v: v)

        // Polish (one, few, many, other)
        case "pl":
            return polishRules(i: i, v: v)

        // Russian and Ukrainian (one, few, many, other)
        case "ru", "uk":
            return russianUkrainianRules(i: i, v: v)

        // Belarusian (one, few, many, other)
        case "be":
            return belarusianRules(n: n, i: i, v: v)

        // Croatian, Serbian, Bosnian (one, few, other)
        case "hr", "sr", "bs":
            return croatianSerbianRules(i: i, v: v, f: f)

        // Slovenian (one, two, few, other)
        case "sl":
            return slovenianRules(i: i, v: v)

        // Lithuanian (one, few, many, other)
        case "lt":
            return lithuanianRules(n: n, i: i, v: v, f: f)

        // Latvian (zero, one, other)
        case "lv":
            return latvianRules(n: n, i: i, v: v, f: f)

        // Hebrew (one, two, other)
        case "he":
            return hebrewRules(i: i, v: v)

        // Arabic (zero, one, two, few, many, other)
        case "ar":
            return arabicRules(n: n, i: i)

        // Welsh (zero, one, two, few, many, other)
        case "cy":
            return welshRules(n: n)

        // Romanian (one, few, other)
        case "ro":
            return romanianRules(i: i, v: v, n: n)

        // Macedonian (one, other) - similar to English but slightly different
        case "mk":
            return macedonianRules(i: i, v: v, f: f)

        // Maltese (one, two, few, many, other)
        case "mt":
            return malteseRules(n: n)

        // Irish (one, two, few, many, other)
        case "ga":
            return irishRules(n: n)

        // Scottish Gaelic (one, two, few, other)
        case "gd":
            return scottishGaelicRules(n: n)

        // Breton (one, two, few, many, other)
        case "br":
            return bretonRules(n: n)

        // Hindi, Bengali, Gujarati, Kannada, Farsi (one, other) - i=0 or n=1 rule
        case "hi", "bn", "gu", "kn", "fa":
            return indicRules(i: i, n: n)

        // Punjabi (one, other) - n=0..1 rule
        case "pa":
            return punjabiRules(n: n)

        // Sinhala (one, other) - special rule
        case "si":
            return sinhalaRules(n: n, i: i, f: f)

        // Hungarian, Turkish, and other simple languages (one, other)
        case "hu", "tr", "az", "ka", "hy", "is":
            return simpleOneOtherRules(n: n)

        default:
            // Default to English-like rules for unsupported languages
            return englishLikeRules(i: i, v: v)
        }
    }

    // MARK: - Helper functions for calculating linguistic variables

    private func numberOfFractionalDigits(_ number: Double) -> Int {
        let string = String(number)
        if let dotIndex = string.firstIndex(of: ".") {
            let afterDot = String(string[string.index(after: dotIndex)...])
            // Remove trailing zeros
            let trimmed = afterDot.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            return trimmed.isEmpty ? 0 : afterDot.count
        }
        return 0
    }

    private func fractionalPart(_ number: Double) -> Int {
        let string = String(number)
        if let dotIndex = string.firstIndex(of: ".") {
            let afterDot = String(string[string.index(after: dotIndex)...])
            return Int(afterDot) ?? 0
        }
        return 0
    }

    private func trimmedFractionalPart(_ number: Double) -> Int {
        let string = String(number)
        if let dotIndex = string.firstIndex(of: ".") {
            let afterDot = String(string[string.index(after: dotIndex)...])
            let trimmed = afterDot.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
            return Int(trimmed) ?? 0
        }
        return 0
    }

    private func scientificExponent(_ number: Double) -> Int {
        if number == 0 { return 0 }
        return Int(floor(log10(abs(number))))
    }

    // MARK: - Language-specific plural rules

    private func englishLikeRules(i: Int, v: Int) -> PluralCategory {
        // i = 1 and v = 0
        if i == 1 && v == 0 {
            return .one
        }
        return .other
    }

    private func frenchRules(i: Int, v: Int, e: Int) -> PluralCategory {
        // i = 0,1
        if i == 0 || i == 1 {
            return .one
        }
        // e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5
        if (e == 0 && i != 0 && i % 1_000_000 == 0 && v == 0) || (e < 0 || e > 5) {
            return .many
        }
        return .other
    }

    private func spanishRules(n: Double, i: Int, v: Int, e: Int) -> PluralCategory {
        // n = 1
        if n == 1.0 {
            return .one
        }
        // e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5
        if (e == 0 && i != 0 && i % 1_000_000 == 0 && v == 0) || (e < 0 || e > 5) {
            return .many
        }
        return .other
    }

    private func portugueseRules(i: Int, v: Int, e: Int) -> PluralCategory {
        // i = 0..1
        if i >= 0 && i <= 1 {
            return .one
        }
        // e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5
        if (e == 0 && i != 0 && i % 1_000_000 == 0 && v == 0) || (e < 0 || e > 5) {
            return .many
        }
        return .other
    }

    private func italianRules(i: Int, v: Int, e: Int) -> PluralCategory {
        // i = 1 and v = 0
        if i == 1 && v == 0 {
            return .one
        }
        // e = 0 and i != 0 and i % 1000000 = 0 and v = 0 or e != 0..5
        if (e == 0 && i != 0 && i % 1_000_000 == 0 && v == 0) || (e < 0 || e > 5) {
            return .many
        }
        return .other
    }

    private func czechSlovakRules(i: Int, v: Int) -> PluralCategory {
        // i = 1 and v = 0
        if i == 1 && v == 0 {
            return .one
        }
        // i = 2..4 and v = 0
        if i >= 2 && i <= 4 && v == 0 {
            return .few
        }
        // v != 0
        if v != 0 {
            return .many
        }
        return .other
    }

    private func polishRules(i: Int, v: Int) -> PluralCategory {
        // For decimals, return .other
        if v != 0 {
            return .other
        }

        // i = 1 and v = 0
        if i == 1 && v == 0 {
            return .one
        }
        // v = 0 and i % 10 = 2..4 and i % 100 != 12..14
        if v == 0 && (i % 10 >= 2 && i % 10 <= 4) && !(i % 100 >= 12 && i % 100 <= 14) {
            return .few
        }
        // v = 0 and i != 1 and i % 10 = 0..1 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 12..14
        if (v == 0 && i != 1 && (i % 10 == 0 || i % 10 == 1))
            || (v == 0 && (i % 10 >= 5 && i % 10 <= 9))
            || (v == 0 && (i % 100 >= 12 && i % 100 <= 14))
        {
            return .many
        }
        return .other
    }

    private func russianUkrainianRules(i: Int, v: Int) -> PluralCategory {
        // For decimals, return .other
        if v != 0 {
            return .other
        }

        // v = 0 and i % 10 = 1 and i % 100 != 11
        if v == 0 && i % 10 == 1 && i % 100 != 11 {
            return .one
        }
        // v = 0 and i % 10 = 2..4 and i % 100 != 12..14
        if v == 0 && (i % 10 >= 2 && i % 10 <= 4) && !(i % 100 >= 12 && i % 100 <= 14) {
            return .few
        }
        // v = 0 and i % 10 = 0 or v = 0 and i % 10 = 5..9 or v = 0 and i % 100 = 11..14
        if (v == 0 && i % 10 == 0) || (v == 0 && (i % 10 >= 5 && i % 10 <= 9))
            || (v == 0 && (i % 100 >= 11 && i % 100 <= 14))
        {
            return .many
        }
        return .other
    }

    private func belarusianRules(n: Double, i: Int, v: Int) -> PluralCategory {
        // n % 10 = 1 and n % 100 != 11
        if Int(n) % 10 == 1 && Int(n) % 100 != 11 {
            return .one
        }
        // n % 10 = 2..4 and n % 100 != 12..14
        if (Int(n) % 10 >= 2 && Int(n) % 10 <= 4) && !(Int(n) % 100 >= 12 && Int(n) % 100 <= 14) {
            return .few
        }
        // n % 10 = 0 or n % 10 = 5..9 or n % 100 = 11..14
        if Int(n) % 10 == 0 || (Int(n) % 10 >= 5 && Int(n) % 10 <= 9)
            || (Int(n) % 100 >= 11 && Int(n) % 100 <= 14)
        {
            return .many
        }
        return .other
    }

    private func croatianSerbianRules(i: Int, v: Int, f: Int) -> PluralCategory {
        // v = 0 and i % 10 = 1 and i % 100 != 11 or f % 10 = 1 and f % 100 != 11
        if (v == 0 && i % 10 == 1 && i % 100 != 11) || (f % 10 == 1 && f % 100 != 11) {
            return .one
        }
        // v = 0 and i % 10 = 2..4 and i % 100 != 12..14 or f % 10 = 2..4 and f % 100 != 12..14
        if (v == 0 && (i % 10 >= 2 && i % 10 <= 4) && !(i % 100 >= 12 && i % 100 <= 14))
            || ((f % 10 >= 2 && f % 10 <= 4) && !(f % 100 >= 12 && f % 100 <= 14))
        {
            return .few
        }
        return .other
    }

    private func slovenianRules(i: Int, v: Int) -> PluralCategory {
        // v = 0 and i % 100 = 1
        if v == 0 && i % 100 == 1 {
            return .one
        }
        // v = 0 and i % 100 = 2
        if v == 0 && i % 100 == 2 {
            return .two
        }
        // v = 0 and i % 100 = 3..4 or v != 0
        if (v == 0 && (i % 100 >= 3 && i % 100 <= 4)) || v != 0 {
            return .few
        }
        return .other
    }

    private func lithuanianRules(n: Double, i: Int, v: Int, f: Int) -> PluralCategory {
        // n % 10 = 1 and n % 100 != 11..19
        if Int(n) % 10 == 1 && !(Int(n) % 100 >= 11 && Int(n) % 100 <= 19) {
            return .one
        }
        // n % 10 = 2..9 and n % 100 != 11..19
        if (Int(n) % 10 >= 2 && Int(n) % 10 <= 9) && !(Int(n) % 100 >= 11 && Int(n) % 100 <= 19) {
            return .few
        }
        // f != 0
        if f != 0 {
            return .many
        }
        return .other
    }

    private func latvianRules(n: Double, i: Int, v: Int, f: Int) -> PluralCategory {
        // n % 10 = 0 or n % 100 = 11..19 or v = 2 and f % 100 = 11..19
        if Int(n) % 10 == 0 || (Int(n) % 100 >= 11 && Int(n) % 100 <= 19)
            || (v == 2 && (f % 100 >= 11 && f % 100 <= 19))
        {
            return .zero
        }
        // n % 10 = 1 and n % 100 != 11 or v = 2 and f % 10 = 1 and f % 100 != 11 or v != 2 and f % 10 = 1
        if (Int(n) % 10 == 1 && Int(n) % 100 != 11) || (v == 2 && f % 10 == 1 && f % 100 != 11)
            || (v != 2 && f % 10 == 1)
        {
            return .one
        }
        return .other
    }

    private func hebrewRules(i: Int, v: Int) -> PluralCategory {
        // i = 1 and v = 0 or i = 0 and v != 0
        if (i == 1 && v == 0) || (i == 0 && v != 0) {
            return .one
        }
        // i = 2 and v = 0
        if i == 2 && v == 0 {
            return .two
        }
        return .other
    }

    private func arabicRules(n: Double, i: Int) -> PluralCategory {
        // n = 0
        if n == 0 {
            return .zero
        }
        // n = 1
        if n == 1 {
            return .one
        }
        // n = 2
        if n == 2 {
            return .two
        }
        // n % 100 = 3..10
        if i % 100 >= 3 && i % 100 <= 10 {
            return .few
        }
        // n % 100 = 11..99
        if i % 100 >= 11 && i % 100 <= 99 {
            return .many
        }
        return .other
    }

    private func welshRules(n: Double) -> PluralCategory {
        // n = 0
        if n == 0 {
            return .zero
        }
        // n = 1
        if n == 1 {
            return .one
        }
        // n = 2
        if n == 2 {
            return .two
        }
        // n = 3
        if n == 3 {
            return .few
        }
        // n = 6
        if n == 6 {
            return .many
        }
        return .other
    }

    private func romanianRules(i: Int, v: Int, n: Double) -> PluralCategory {
        // i = 1 and v = 0
        if i == 1 && v == 0 {
            return .one
        }
        // v != 0 or n = 0 or n != 1 and n % 100 = 1..19
        if v != 0 || n == 0 || (n != 1 && (Int(n) % 100 >= 1 && Int(n) % 100 <= 19)) {
            return .few
        }
        return .other
    }

    private func simpleOneOtherRules(n: Double) -> PluralCategory {
        // n = 1
        if n == 1.0 {
            return .one
        }
        return .other
    }

    private func macedonianRules(i: Int, v: Int, f: Int) -> PluralCategory {
        // v = 0 and i % 10 = 1 and i % 100 != 11 or f % 10 = 1 and f % 100 != 11
        if (v == 0 && i % 10 == 1 && i % 100 != 11) || (f % 10 == 1 && f % 100 != 11) {
            return .one
        }
        return .other
    }

    private func malteseRules(n: Double) -> PluralCategory {
        // n = 1
        if n == 1 {
            return .one
        }
        // n = 2
        if n == 2 {
            return .two
        }
        // n = 0 or n % 100 = 3..10
        if n == 0 || (Int(n) % 100 >= 3 && Int(n) % 100 <= 10) {
            return .few
        }
        // n % 100 = 11..19
        if Int(n) % 100 >= 11 && Int(n) % 100 <= 19 {
            return .many
        }
        return .other
    }

    private func irishRules(n: Double) -> PluralCategory {
        // n = 1
        if n == 1 {
            return .one
        }
        // n = 2
        if n == 2 {
            return .two
        }
        // n = 3..6
        if n >= 3 && n <= 6 {
            return .few
        }
        // n = 7..10
        if n >= 7 && n <= 10 {
            return .many
        }
        return .other
    }

    private func scottishGaelicRules(n: Double) -> PluralCategory {
        // n = 1,11
        if n == 1 || n == 11 {
            return .one
        }
        // n = 2,12
        if n == 2 || n == 12 {
            return .two
        }
        // n = 3..10,13..19
        if (n >= 3 && n <= 10) || (n >= 13 && n <= 19) {
            return .few
        }
        return .other
    }

    private func bretonRules(n: Double) -> PluralCategory {
        let intN = Int(n)
        // n % 10 = 1 and n % 100 != 11,71,91
        if intN % 10 == 1 && !(intN % 100 == 11 || intN % 100 == 71 || intN % 100 == 91) {
            return .one
        }
        // n % 10 = 2 and n % 100 != 12,72,92
        if intN % 10 == 2 && !(intN % 100 == 12 || intN % 100 == 72 || intN % 100 == 92) {
            return .two
        }
        // n % 10 = 3,4,9 and n % 100 != 10..19,70..79,90..99
        if (intN % 10 == 3 || intN % 10 == 4 || intN % 10 == 9)
            && !((intN % 100 >= 10 && intN % 100 <= 19) || (intN % 100 >= 70 && intN % 100 <= 79)
                || (intN % 100 >= 90 && intN % 100 <= 99))
        {
            return .few
        }
        // n != 0 and n % 1000000 = 0
        if n != 0 && Int(n) % 1_000_000 == 0 {
            return .many
        }
        return .other
    }

    private func indicRules(i: Int, n: Double) -> PluralCategory {
        // i = 0 or n = 1
        if i == 0 || n == 1 {
            return .one
        }
        return .other
    }

    private func punjabiRules(n: Double) -> PluralCategory {
        // n = 0..1
        if n >= 0 && n <= 1 {
            return .one
        }
        return .other
    }

    private func sinhalaRules(n: Double, i: Int, f: Int) -> PluralCategory {
        // n = 0,1 or i = 0 and f = 1
        if n == 0 || n == 1 || (i == 0 && f == 1) {
            return .one
        }
        return .other
    }
}

extension PluralRules {
    static func pluralRules(for locale: Locale) -> PluralRules {
        return PluralRules(for: locale)
    }
}
