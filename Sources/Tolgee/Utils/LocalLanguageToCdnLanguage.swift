/// Converts a lowercase local language identifier to a properly capitalized CDN language format.
///
/// Takes a lowercase language identifier (e.g., "pt-br", "zh-hans", "zh-hans-cn") and converts it to
/// the capitalized format expected by the CDN (e.g., "pt-BR", "zh-Hans", "zh-Hans-CN").
///
/// Follows BCP 47 conventions:
/// - Language codes (2-3 letters) remain lowercase
/// - Script codes (4 letters) are capitalized (first letter uppercase, rest lowercase)
/// - Region codes (2 letters or 3 digits) are uppercased
///
/// - Parameter localLanguage: The lowercase language identifier (e.g., "pt-br", "en", "zh-hans-cn")
/// - Returns: The capitalized language identifier suitable for CDN use (e.g., "pt-BR", "en", "zh-Hans-CN")
func localLanguageToCdnLanguage(_ localLanguage: String) -> String {
    // Split by hyphen to handle language-region and language-script identifiers
    let components = localLanguage.split(separator: "-")

    if components.isEmpty {
        return localLanguage
    }

    // First component (language code) stays lowercase
    var result = String(components[0].lowercased())

    // Subsequent components are formatted based on their type
    for component in components.dropFirst() {
        let componentStr = String(component)

        // Region codes (2 letters or 3 digits) are fully uppercased
        if componentStr.count == 2
            || (componentStr.count == 3 && componentStr.allSatisfy { $0.isNumber })
        {
            result += "-" + componentStr.uppercased()
        }
        // Script codes (4 letters) are capitalized (first letter uppercase, rest lowercase)
        else if componentStr.count == 4 && componentStr.allSatisfy({ $0.isLetter }) {
            result += "-" + componentStr.capitalized
        }
        // Default to capitalization for other cases
        else {
            result += "-" + componentStr.capitalized
        }
    }

    return result
}
