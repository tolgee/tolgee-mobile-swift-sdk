import Foundation

/// Parser for handling JSON translation data and ICU message formatting
struct JSONParser {

    /// Loads translations from JSON data
    /// - Parameters:
    ///   - jsonData: The JSON data to parse
    ///   - table: The table name for the translations (empty for base table)
    /// - Returns: Dictionary of key-value translation pairs
    /// - Throws: DecodingError if JSON parsing fails
    static func loadTranslations(from jsonData: Data, table: String = "") throws -> [String: String]
    {
        let decoder = JSONDecoder()
        return try decoder.decode([String: String].self, from: jsonData)
    }

    /// Loads translations from JSON string
    /// - Parameters:
    ///   - jsonString: The JSON string to parse
    ///   - table: The table name for the translations (empty for base table)
    /// - Returns: Dictionary of key-value translation pairs
    /// - Throws: TolgeeError.invalidJSONString if string conversion fails, or DecodingError if JSON parsing fails
    static func loadTranslations(from jsonString: String, table: String = "") throws -> [String:
        String]
    {
        guard let data = jsonString.data(using: .utf8) else {
            throw TolgeeError.invalidJSONString
        }
        return try loadTranslations(from: data, table: table)
    }

    /// Parses ICU message format strings with arguments and locale-aware plural rules
    /// - Parameters:
    ///   - icuString: The ICU formatted string
    ///   - arguments: Arguments to substitute in the string
    ///   - locale: Locale for plural rule evaluation
    /// - Returns: Formatted string with arguments and plural forms resolved
    static func parseICUString(
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

    /// Parses plural forms in ICU message format
    /// - Parameters:
    ///   - string: The string containing plural patterns
    ///   - arguments: Arguments for plural evaluation
    ///   - locale: Locale for plural rule evaluation
    /// - Returns: String with plural forms resolved
    private static func parsePluralForms(
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

    /// Determines the appropriate plural form based on locale-specific rules
    /// - Parameters:
    ///   - argument: The numeric argument for plural evaluation
    ///   - oneForm: The singular form text
    ///   - fewForm: The few form text (optional, used in languages like Czech, Russian)
    ///   - otherForm: The plural/other form text
    ///   - locale: Locale for plural rule evaluation
    /// - Returns: The appropriate form text based on the numeric value and locale rules
    private static func getPluralForm(
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

        // Use the comprehensive PluralRules system
        let pluralRules = PluralRules.pluralRules(for: locale)
        let category = pluralRules.category(for: numericValue)

        switch category {
        case .one:
            return oneForm
        case .few:
            return fewForm ?? otherForm
        case .zero, .two, .many, .other:
            return otherForm
        }
    }
}
