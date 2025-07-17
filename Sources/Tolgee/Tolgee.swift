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
        // Basic ICU plural parsing for patterns like:
        // {0, plural, one {I have # apple} other {I have # apples}}
        let pluralRegex = /\{(\d+),\s*plural,\s*one\s*\{([^}]+)\}\s*other\s*\{([^}]+)\}\}/

        var result = string

        // Process matches in reverse order to avoid index shifting
        let matches = Array(result.matches(of: pluralRegex)).reversed()

        for match in matches {
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

            // Replace # with the actual number in the selected form
            let finalReplacement = replacement.replacingOccurrences(of: "#", with: "\(argument)")

            result = result.replacingOccurrences(of: fullMatch, with: finalReplacement)
        }

        return result
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
