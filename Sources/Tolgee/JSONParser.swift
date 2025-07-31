import Foundation

/// Represents a translation entry that can be either a simple string or have plural variants
enum TranslationEntry: Equatable, Sendable {
    case simple(String)
    case plural(PluralVariants)
}

/// Contains pre-computed plural variants for different plural categories
struct PluralVariants: Equatable, Sendable {
    let one: String
    let few: String?
    let other: String

    /// Gets the appropriate variant for a numeric value and locale
    func variant(for numericValue: Double, locale: Locale) -> String {
        let pluralRules = PluralRules.pluralRules(for: locale)
        let category = pluralRules.category(for: numericValue)

        switch category {
        case .one:
            return one
        case .few:
            return few ?? other
        case .zero, .two, .many, .other:
            return other
        }
    }
}

/// Parser for handling JSON translation data and ICU message formatting
struct JSONParser {

    /// Loads translations from JSON data and pre-computes plural variants
    /// - Parameters:
    ///   - jsonData: The JSON data to parse
    ///   - table: The table name for the translations (empty for base table)
    /// - Returns: Dictionary of key-TranslationEntry pairs with pre-computed plurals
    /// - Throws: DecodingError if JSON parsing fails
    static func loadTranslations(from jsonData: Data, table: String = "") throws -> [String:
        TranslationEntry]
    {
        let decoder = JSONDecoder()
        let rawTranslations = try decoder.decode([String: String].self, from: jsonData)

        var processedTranslations: [String: TranslationEntry] = [:]

        for (key, value) in rawTranslations {
            processedTranslations[key] = parseTranslationEntry(value)
        }

        return processedTranslations
    }

    /// Loads translations from JSON string and pre-computes plural variants
    /// - Parameters:
    ///   - jsonString: The JSON string to parse
    ///   - table: The table name for the translations (empty for base table)
    /// - Returns: Dictionary of key-TranslationEntry pairs with pre-computed plurals
    /// - Throws: TolgeeError.invalidJSONString if string conversion fails, or DecodingError if JSON parsing fails
    static func loadTranslations(from jsonString: String, table: String = "") throws -> [String:
        TranslationEntry]
    {
        guard let data = jsonString.data(using: .utf8) else {
            throw TolgeeError.invalidJSONString
        }
        return try loadTranslations(from: data, table: table)
    }

    /// Parses a translation string and extracts plural variants if present
    /// - Parameter value: The translation string to parse
    /// - Returns: TranslationEntry with either simple string or pre-computed plural variants
    private static func parseTranslationEntry(_ value: String) -> TranslationEntry {
        // Check for three-form plural pattern (one/few/other)
        let threePluralRegex =
            /\{(\d+),\s*plural,\s*one\s*\{([^}]+)\}\s*few\s*\{([^}]+)\}\s*other\s*\{([^}]+)\}\s*\}/

        if let match = value.firstMatch(of: threePluralRegex) {
            let oneForm = String(match.2)
            let fewForm = String(match.3)
            let otherForm = String(match.4)

            return .plural(PluralVariants(one: oneForm, few: fewForm, other: otherForm))
        }

        // Check for two-form plural pattern (one/other)
        let twoPluralRegex = /\{(\d+),\s*plural,\s*one\s*\{([^}]+)\}\s*other\s*\{([^}]+)\}\}/

        if let match = value.firstMatch(of: twoPluralRegex) {
            let oneForm = String(match.2)
            let otherForm = String(match.3)

            return .plural(PluralVariants(one: oneForm, few: nil, other: otherForm))
        }

        // No plural pattern found, return as simple string
        return .simple(value)
    }

    /// Formats a translation entry with arguments and locale
    /// - Parameters:
    ///   - entry: The pre-parsed translation entry
    ///   - arguments: Arguments to substitute in the string
    ///   - locale: Locale for plural rule evaluation
    /// - Returns: Formatted string with arguments resolved
    static func formatTranslation(
        _ entry: TranslationEntry, with arguments: [CVarArg], locale: Locale = .current
    ) -> String {
        switch entry {
        case .simple(let string):
            if arguments.isEmpty {
                return string  // No arguments, return simple string
            } else {
                return substituteSimplePlaceholders(in: string, with: arguments)
            }
        case .plural(let pluralVariants):
            // For plural entries, we need to find the numeric argument (usually the first one)
            guard let firstArgument = arguments.first else {
                return pluralVariants.other
            }

            let numericValue = extractNumericValue(from: firstArgument)
            let selectedVariant = pluralVariants.variant(for: numericValue, locale: locale)

            // Replace # and format specifiers with the actual number
            var result = selectedVariant.replacingOccurrences(of: "#", with: "\(firstArgument)")
            result = substituteFormatSpecifiers(in: result, with: firstArgument)

            // Handle remaining placeholders if there are more arguments
            return substituteSimplePlaceholders(in: result, with: arguments)
        }
    }

    /// Extracts numeric value from CVarArg for plural evaluation
    /// - Parameter argument: The argument to extract numeric value from
    /// - Returns: Numeric value as Double
    private static func extractNumericValue(from argument: CVarArg) -> Double {
        if let intValue = argument as? Int {
            return Double(intValue)
        } else if let doubleValue = argument as? Double {
            return doubleValue
        } else if let floatValue = argument as? Float {
            return Double(floatValue)
        } else {
            return 0.0  // Default for non-numeric arguments
        }
    }

    /// Substitutes simple placeholders {0}, {1}, etc. and format specifiers with arguments
    /// - Parameters:
    ///   - string: The string containing placeholders
    ///   - arguments: Arguments to substitute
    /// - Returns: String with placeholders replaced
    private static func substituteSimplePlaceholders(in string: String, with arguments: [CVarArg])
        -> String
    {
        var result = string

        // Handle indexed placeholders {0}, {1}, etc.
        for (index, argument) in arguments.enumerated() {
            let placeholder = "{\(index)}"
            if result.contains(placeholder) {
                result = result.replacingOccurrences(of: placeholder, with: "\(argument)")
            }
        }

        // Handle format specifiers like %@, %d, etc. with the first argument by default
        if !arguments.isEmpty {
            result = substituteFormatSpecifiers(in: result, with: arguments[0])
        }

        return result
    }

    /// Substitutes format specifiers like %d, %@, etc. with the given argument
    /// - Parameters:
    ///   - string: The string containing format specifiers
    ///   - argument: The argument to substitute
    /// - Returns: String with format specifiers replaced
    private static func substituteFormatSpecifiers(in string: String, with argument: CVarArg)
        -> String
    {
        var result = string
        result = result.replacingOccurrences(of: "%lf", with: "\(argument)")
        result = result.replacingOccurrences(of: "%lld", with: "\(argument)")
        result = result.replacingOccurrences(of: "%@", with: "\(argument)")
        result = result.replacingOccurrences(of: "%d", with: "\(argument)")
        result = result.replacingOccurrences(of: "%i", with: "\(argument)")
        return result
    }

    /// Legacy method for backward compatibility - parses ICU string on demand
    /// Note: This is less efficient than pre-computing during load time
    /// - Parameters:
    ///   - icuString: The ICU formatted string
    ///   - arguments: Arguments to substitute in the string
    ///   - locale: Locale for plural rule evaluation
    /// - Returns: Formatted string with arguments and plural forms resolved
    static func parseICUString(
        _ icuString: String, with arguments: [CVarArg], locale: Locale = .current
    ) -> String {
        let entry = parseTranslationEntry(icuString)
        return formatTranslation(entry, with: arguments, locale: locale)
    }
}
