import Foundation
import Synchronization

public enum TolgeeError: Error {
    case invalidJSONString
    case translationNotFound
}

@MainActor
public final class Tolgee {
    public static let shared = Tolgee()

    private var apiKey: String?
    private var apiUrl: String?
    private var translations: [String: String] = [:]

    private init() {
        // Initialize Tolgee SDK
        // This is where you would set up your Tolgee configuration, e.g. API keys, languages, etc.
    }

    public func initialize(apiUrl: String, apiKey: String) {
        self.apiUrl = apiUrl
        self.apiKey = apiKey
    }

    public func fetch() {

    }

    public func loadTranslations(from jsonData: Data) throws {
        let decoder = JSONDecoder()
        let translations = try decoder.decode([String: String].self, from: jsonData)
        self.translations = translations
    }

    public func loadTranslations(from jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw TolgeeError.invalidJSONString
        }
        try loadTranslations(from: data)
    }

    public func loadTranslations(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try loadTranslations(from: data)
    }

    private func parseICUString(
        _ icuString: String, with arguments: [CVarArg], locale: Locale = .current
    ) -> String {
        var result = icuString

        // Handle simple placeholder replacement {0}, {1}, etc.
        for (index, argument) in arguments.enumerated() {
            let placeholder = "{\(index)}"
            if result.contains(placeholder) {
                result = result.replacingOccurrences(of: placeholder, with: "\(argument)")
            }
        }

        // Handle plural forms
        result = parsePluralForms(result, with: arguments, locale: locale)

        return result
    }

    private func parsePluralForms(
        _ string: String, with arguments: [CVarArg], locale: Locale = .current
    ) -> String {
        // ICU plural parsing for patterns like:
        // {0, plural, one {I have # apple} other {I have # apples}}
        // {0, plural, one {Mám # jablko} few {Mám # jablka} other {Mám # jablek}}

        // First try to match the three-form pattern (one/few/other)
        let threePluralRegex =
            /\{(\d+),\s*plural,\s*one\s*\{([^}]+)\}\s*few\s*\{([^}]+)\}\s*other\s*\{([^}]+)\}\s*\}/

        var result = string

        // Process three-form matches first
        let threeFormMatches = Array(result.matches(of: threePluralRegex)).reversed()

        for match in threeFormMatches {
            let fullMatch = match.0
            let indexString = String(match.1)
            let oneForm = String(match.2)
            let fewForm = String(match.3)
            let otherForm = String(match.4)

            guard let argumentIndex = Int(indexString),
                argumentIndex < arguments.count
            else { continue }

            let argument = arguments[argumentIndex]
            let replacement: String

            // Use locale-aware plural rules
            replacement = getPluralForm(
                argument: argument,
                oneForm: oneForm,
                fewForm: fewForm,
                otherForm: otherForm,
                locale: locale
            )

            // Replace # and format specifiers with the actual number in the selected form
            var finalReplacement = replacement.replacingOccurrences(of: "#", with: "\(argument)")

            // Also replace common format specifiers
            finalReplacement = finalReplacement.replacingOccurrences(of: "%lf", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(
                of: "%lld", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%@", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%d", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%i", with: "\(argument)")

            result = result.replacingOccurrences(of: fullMatch, with: finalReplacement)
        }

        // Then handle two-form patterns (one/other) for backward compatibility
        let twoPluralRegex = /\{(\d+),\s*plural,\s*one\s*\{([^}]+)\}\s*other\s*\{([^}]+)\}\}/

        let twoFormMatches = Array(result.matches(of: twoPluralRegex)).reversed()

        for match in twoFormMatches {
            let fullMatch = match.0
            let indexString = String(match.1)
            let singularForm = String(match.2)
            let pluralForm = String(match.3)

            guard let argumentIndex = Int(indexString),
                argumentIndex < arguments.count
            else { continue }

            let argument = arguments[argumentIndex]
            let replacement: String

            // Use locale-aware plural rules for two-form pattern
            replacement = getPluralForm(
                argument: argument,
                oneForm: singularForm,
                fewForm: nil as String?,
                otherForm: pluralForm,
                locale: locale
            )

            // Replace # and format specifiers with the actual number in the selected form
            var finalReplacement = replacement.replacingOccurrences(of: "#", with: "\(argument)")

            // Also replace common format specifiers
            finalReplacement = finalReplacement.replacingOccurrences(of: "%lf", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(
                of: "%lld", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%@", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%d", with: "\(argument)")
            finalReplacement = finalReplacement.replacingOccurrences(of: "%i", with: "\(argument)")

            result = result.replacingOccurrences(of: fullMatch, with: finalReplacement)
        }

        return result
    }

    private func getPluralForm(
        argument: CVarArg,
        oneForm: String,
        fewForm: String?,
        otherForm: String,
        locale: Locale
    ) -> String {
        // Convert argument to a number for plural rule evaluation
        let numericValue: Double

        if let intValue = argument as? Int {
            numericValue = Double(intValue)
        } else if let doubleValue = argument as? Double {
            numericValue = doubleValue
        } else if let floatValue = argument as? Float {
            numericValue = Double(floatValue)
        } else {
            // Non-numeric arguments use "other" form
            return otherForm
        }

        // Use NSNumber to leverage Foundation's plural rules
        let number = NSNumber(value: numericValue)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale

        // Get the plural rule for this locale and number
        let pluralRule = getPluralRule(for: number, locale: locale)

        switch pluralRule {
        case .one:
            return oneForm
        case .few:
            return fewForm ?? otherForm
        case .other:
            return otherForm
        }
    }

    private enum PluralRule {
        case one
        case few
        case other
    }

    private func getPluralRule(for number: NSNumber, locale: Locale) -> PluralRule {
        let doubleValue = number.doubleValue
        let intValue = number.intValue
        let isInteger = doubleValue == Double(intValue)

        // Get language code for locale-specific rules
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        switch languageCode {
        case "cs":  // Czech
            return getCzechPluralRule(value: doubleValue, isInteger: isInteger)
        case "sk":  // Slovak (similar to Czech)
            return getCzechPluralRule(value: doubleValue, isInteger: isInteger)
        case "pl":  // Polish
            return getPolishPluralRule(value: doubleValue, isInteger: isInteger)
        case "ru", "uk", "be":  // Russian, Ukrainian, Belarusian
            return getSlavicPluralRule(value: doubleValue, isInteger: isInteger)
        default:  // English and other languages (simple one/other)
            return getSimplePluralRule(value: doubleValue)
        }
    }

    private func getCzechPluralRule(value: Double, isInteger: Bool) -> PluralRule {
        // Czech plural rules (CLDR):
        // one: 1 (exactly 1, including 1.0)
        // few: 2-4 (integers only, so 2.0, 3.0, 4.0 but not 2.1)
        // other: 0, 5+, non-integers except x.0

        if value == 1.0 {
            return .one
        } else if isInteger && value >= 2.0 && value <= 4.0 {
            return .few
        } else {
            return .other
        }
    }

    private func getPolishPluralRule(value: Double, isInteger: Bool) -> PluralRule {
        // Polish plural rules (simplified)
        if value == 1.0 {
            return .one
        } else if isInteger && value >= 2.0 && value <= 4.0 {
            return .few
        } else {
            return .other
        }
    }

    private func getSlavicPluralRule(value: Double, isInteger: Bool) -> PluralRule {
        // Russian/Ukrainian/Belarusian rules (simplified)
        if !isInteger {
            return .other
        }

        let intValue = Int(value)
        let mod10 = intValue % 10
        let mod100 = intValue % 100

        if intValue == 1 {
            return .one
        } else if mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14) {
            return .few
        } else {
            return .other
        }
    }

    private func getSimplePluralRule(value: Double) -> PluralRule {
        // Simple English-style rules: 1 = one, everything else = other
        return value == 1.0 ? .one : .other
    }

    public func translate(_ key: String, locale: Locale = .current) -> String {
        // First try to get translation from loaded translations
        if let icuString = translations[key] {
            return icuString
        }

        // Fallback to NSLocalizedString
        return NSLocalizedString(key, comment: "")
    }

    public func translate(_ key: String, _ arguments: CVarArg..., locale: Locale = .current)
        -> String
    {
        // First try to get translation from loaded translations
        if let icuString = translations[key] {
            return parseICUString(icuString, with: arguments, locale: locale)
        }

        // Fallback to NSLocalizedString
        let localizedString = NSLocalizedString(key, comment: "")

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return parseICUString(localizedString, with: arguments, locale: locale)
        }

        return localizedString
    }
}
