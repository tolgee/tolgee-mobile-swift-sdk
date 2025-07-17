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

    private func parseICUString(_ icuString: String, with arguments: [CVarArg]) -> String {
        var result = icuString

        // Handle simple placeholder replacement {0}, {1}, etc.
        for (index, argument) in arguments.enumerated() {
            let placeholder = "{\(index)}"
            if result.contains(placeholder) {
                result = result.replacingOccurrences(of: placeholder, with: "\(argument)")
            }
        }

        // Handle plural forms
        result = parsePluralForms(result, with: arguments)

        return result
    }

    private func parsePluralForms(_ string: String, with arguments: [CVarArg]) -> String {
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

            // Determine which form to use based on Czech plural rules
            if let number = argument as? Int {
                replacement = getCzechPluralForm(
                    number: number, oneForm: oneForm, fewForm: fewForm, otherForm: otherForm)
            } else if let number = argument as? Double {
                // For non-integer doubles, use "other" form, for integer doubles use Czech rules
                if number == floor(number) {
                    replacement = getCzechPluralForm(
                        number: Int(number), oneForm: oneForm, fewForm: fewForm,
                        otherForm: otherForm)
                } else {
                    replacement = otherForm
                }
            } else if let number = argument as? Float {
                // For non-integer floats, use "other" form, for integer floats use Czech rules
                if number == floor(number) {
                    replacement = getCzechPluralForm(
                        number: Int(number), oneForm: oneForm, fewForm: fewForm,
                        otherForm: otherForm)
                } else {
                    replacement = otherForm
                }
            } else {
                replacement = otherForm  // Default to other for non-numeric types
            }

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

            // Determine if we should use singular or plural form
            if let number = argument as? Int {
                replacement = number == 1 ? singularForm : pluralForm
            } else if let number = argument as? Double {
                replacement = number == 1.0 ? singularForm : pluralForm
            } else if let number = argument as? Float {
                replacement = number == 1.0 ? singularForm : pluralForm
            } else {
                replacement = pluralForm  // Default to plural for non-numeric types
            }

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

    private func getCzechPluralForm(
        number: Int, oneForm: String, fewForm: String, otherForm: String
    ) -> String {
        // Czech plural rules:
        // one: 1
        // few: 2, 3, 4
        // other: 0, 5, 6, 7, ... and negative numbers
        if number == 1 {
            return oneForm
        } else if number >= 2 && number <= 4 {
            return fewForm
        } else {
            return otherForm
        }
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
            return parseICUString(icuString, with: arguments)
        }

        // Fallback to NSLocalizedString
        let localizedString = NSLocalizedString(key, comment: "")

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return parseICUString(localizedString, with: arguments)
        }

        return localizedString
    }
}
