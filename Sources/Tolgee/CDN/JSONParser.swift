import Foundation

struct PluralVariants: Equatable, Sendable, Decodable {
    var zero: String?
    var one: String?
    var two: String?
    var few: String?
    var many: String?
    var other: String?
}

enum TranslationEntry: Equatable, Sendable {
    case simple(String)
    case plural(PluralVariants)
}

private struct TranslationVariations: Decodable {

    struct Variations: Decodable {
        var plural: PluralVariants?
    }

    var variations: Variations?
}

extension TranslationEntry: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let simpleValue = try? container.decode(String.self) {
            self = .simple(simpleValue)
        } else if let pluralValue = try? container.decode(TranslationVariations.self) {
            // Make this forward compatible with future variations such as device-specific strings
            self = .plural(pluralValue.variations?.plural ?? .init())
        } else {
            throw DecodingError.typeMismatch(
                TranslationEntry.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected string or string variations"
                )
            )
        }
    }
}
struct JSONParser {

    static func loadTranslations(from jsonData: Data, ) throws -> [String:
        TranslationEntry]
    {
        let decoder = JSONDecoder()
        return try decoder.decode([String: TranslationEntry].self, from: jsonData)
    }
}
