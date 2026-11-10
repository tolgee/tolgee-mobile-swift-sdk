import Foundation

/// Problems that stop generation, one per line. They are all collected before the error is thrown, so a tool can
/// show every one of them in one run, the way Xcode's own symbol generator does.
public struct GeneratorError: Error, CustomStringConvertible {
    public let problems: [String]

    public init(_ problems: [String]) {
        self.problems = problems
    }

    public var description: String { problems.joined(separator: "\n") }
}

public struct GeneratedKeys {
    public var code: String
    /// Keys that got no member, with the reason.
    public var warnings: [String]
    /// Keys that deliberately get no member because Tolgee can't serve them, with the reason. Unlike `warnings`,
    /// there is nothing to fix in the catalog.
    public var notes: [String]
}

private struct Catalog: Decodable {
    let sourceLanguage: String
    let strings: [String: Entry]

    struct Entry: Decodable {
        let comment: String?
        let localizations: [String: Localization]?
        /// Xcode's per-string opt-out of symbol generation (`"generatesSymbol" : false`). The same switch
        /// excludes the key here, so one edit in the catalog editor settles a key for both generators.
        let generatesSymbol: Bool?
    }

    struct Localization: Decodable {
        let stringUnit: StringUnit?
        let variations: Variations?
        let substitutions: [String: Substitution]?
    }

    struct StringUnit: Decodable {
        let value: String?
    }

    struct Variations: Decodable {
        let plural: [String: Localization]?
        let device: [String: Localization]?
    }

    struct Substitution: Decodable {
        let argNum: Int?
        let formatSpecifier: String
    }
}

private struct UnsupportedKey: Error {
    let reason: String
}

/// A key the CDN can't serve. It gets no member, so the limitation isn't hidden behind a typed call that
/// looks like every other one but never updates over the air.
private struct UnservableKey: Error {
    let reason: String
}

private let reservedNames: Set = ["key", "table", "arguments", "bundle"]

private let optOut = "set \"generatesSymbol\" : false on it in the catalog"

/// Generates a `TolgeeKey` member for every key in a String Catalog.
///
/// Parameter types come from the format specifiers of all texts of the key (every language, plural form and
/// device variation). A key without any localization uses the key as its text.
///
/// Generation fails where Xcode's own symbol generator fails: a key that can't be named at all, or keys that would
/// all get the same member. Every such key is collected and thrown together in one `GeneratorError`, so one run
/// shows them all. A key with `"generatesSymbol" : false` is excluded, silently, as Xcode excludes it. Keys that
/// can't get a safe member because of their format specifiers are skipped and reported in `warnings`. Keys the CDN
/// can't serve, those with more than one plural argument, are skipped and reported in `notes`, and listed in a
/// comment at the end of the generated code.
public func generateKeys(catalog data: Data, table: String) throws -> GeneratedKeys {
    let catalog = try JSONDecoder().decode(Catalog.self, from: data)
    let nested = table != "Localizable"
    let indent = nested ? "        " : "    "
    var errors: [String] = []
    var warnings: [String] = []
    var notes: [String] = []
    var members: [(key: String, name: String, types: [String], code: String)] = []

    for (key, entry) in catalog.strings.sorted(by: { $0.key < $1.key }) where entry.generatesSymbol != false {
        let name = identifier(for: key)
        guard !name.isEmpty else {
            errors.append("Key \(literal(key)) has no letters or digits to name a member by. Rename it, or \(optOut).")
            continue
        }
        guard !reservedNames.contains(name) else {
            errors.append("Key \(literal(key)) would generate `\(name)`, which TolgeeKey already has. Rename it, or \(optOut).")
            continue
        }
        let types: [String]
        do {
            types = try parameters(of: entry, key: key, sourceLanguage: catalog.sourceLanguage)
        } catch let error as UnsupportedKey {
            warnings.append("Key \(literal(key)) skipped: \(error.reason).")
            continue
        } catch let error as UnservableKey {
            notes.append(
                "Key \(literal(key)) has no member: \(error.reason). Use the string key; it is served from the app bundle only.")
            continue
        }

        var arguments = "TolgeeKey(\(literal(key))"
        if nested { arguments += ", table: \(literal(table))" }

        var member = ""
        if let comment = entry.comment, !comment.isEmpty {
            member += comment.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .map { "\(indent)/// \(withoutControlCharacters($0))\n" }.joined()
            member += "\(indent)///\n"
        }
        member += "\(indent)/// Key \(literal(key))\n"

        if types.isEmpty {
            member += "\(indent)static var `\(name)`: TolgeeKey {\n"
            member += "\(indent)    \(arguments), bundle: tolgeeKeysBundle)\n\(indent)}\n"
        } else {
            let names = types.indices.map { "arg\($0 + 1)" }
            let signature = zip(names, types).map { "_ \($0): \($1)" }.joined(separator: ", ")
            member += "\(indent)static func `\(name)`(\(signature)) -> TolgeeKey {\n"
            member += "\(indent)    \(arguments), arguments: [\(names.joined(separator: ", "))], bundle: tolgeeKeysBundle)\n"
            member += "\(indent)}\n"
        }
        members.append((key, name, types, member))
    }

    let overloads = Dictionary(grouping: members) { "\($0.name)(\($0.types.joined(separator: ",")))" }
    for (_, group) in overloads.sorted(by: { $0.key < $1.key }) where group.count > 1 {
        let keys = group.map { literal($0.key) }.joined(separator: ", ")
        errors.append(
            "Keys \(keys) would all generate `\(group[0].name)`. Rename all but one of them, or "
                + "set \"generatesSymbol\" : false on the ones that need no member.")
    }
    guard errors.isEmpty else { throw GeneratorError(errors) }
    let code = members.map(\.code).joined(separator: "\n")

    var body = code
    if nested {
        var typeName = identifier(for: table)
        guard !typeName.isEmpty else {
            throw GeneratorError(["\(table).xcstrings: the table name can't be turned into a Swift name."])
        }
        if typeName.first != "_" { typeName = typeName.prefix(1).uppercased() + typeName.dropFirst() }
        body = "    enum \(typeName) {\n\(code)    }\n"
    }

    var footer = ""
    if !notes.isEmpty {
        footer = "\n\n// Keys without a member, served from the app bundle only:\n"
            + notes.map { "// \($0)" }.joined(separator: "\n")
    }

    return GeneratedKeys(
        code: """
            // Generated by TolgeeKeysPlugin from \(table).xcstrings. Do not edit.

            import Foundation
            import Tolgee

            #if SWIFT_PACKAGE
                private let tolgeeKeysBundle = Bundle.module
            #else
                private final class TolgeeKeysBundleToken {}
                private let tolgeeKeysBundle = Bundle(for: TolgeeKeysBundleToken.self)
            #endif

            extension TolgeeKey {
            \(body)}\(footer)

            """,
        warnings: warnings, notes: notes)
}

private func parameters(of entry: Catalog.Entry, key: String, sourceLanguage: String) throws -> [String] {
    var allTexts = (entry.localizations ?? [:]).values.flatMap { texts(of: $0, substitutions: [:]) }
    if entry.localizations?[sourceLanguage] == nil {
        allTexts.append((key, [:]))
    }

    var types: [Int: String] = [:]
    for (text, substitutions) in allTexts {
        for (position, type) in try parameters(in: text, substitutions: substitutions) {
            if let existing = types[position], existing != type {
                throw UnsupportedKey(reason: "argument \(position) is \(existing) in one text and \(type) in another")
            }
            types[position] = type
        }
    }
    guard let last = types.keys.max() else { return [] }
    return try (1...last).map { position in
        guard let type = types[position] else {
            throw UnsupportedKey(reason: "no text uses argument \(position)")
        }
        return type
    }
}

private func texts(
    of localization: Catalog.Localization, substitutions inherited: [String: Catalog.Substitution]
) -> [(String, [String: Catalog.Substitution])] {
    let substitutions = inherited.merging(localization.substitutions ?? [:]) { $1 }
    var result = localization.stringUnit?.value.map { [($0, substitutions)] } ?? []
    for variation in [localization.variations?.plural, localization.variations?.device] {
        for nested in (variation ?? [:]).values {
            result += texts(of: nested, substitutions: substitutions)
        }
    }
    return result
}

/// `home.send_money` → `homeSendMoney`, `HOME_TITLE` → `homeTitle`, `My name is %@` → `myNameIs`,
/// `Don't stop` → `dontStop`.
func identifier(for key: String) -> String {
    var text = specifier.stringByReplacingMatches(
        in: key, range: NSRange(key.startIndex..., in: key), withTemplate: " ")
    // Apostrophes join the letters around them instead of splitting a word, so contractions in
    // sentence keys read naturally: `What's new` → `whatsNew`, not `whatSNew`.
    text.removeAll(where: { $0 == "'" || $0 == "\u{2019}" })
    let words = text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    guard let first = words.first else { return "" }
    let name = lowercasingStart(of: first)
        + words.dropFirst().map { word in
            let word = word == word.uppercased() ? word.lowercased() : word
            return word.prefix(1).uppercased() + word.dropFirst()
        }.joined()
    return name.first!.isNumber ? "_" + name : name
}

/// `Hello` → `hello`, `URLPath` → `urlPath`, `HOME` → `home`.
private func lowercasingStart(of word: String) -> String {
    if word == word.uppercased() { return word.lowercased() }
    let length = max(word.prefix(while: \.isUppercase).count - 1, 1)
    return word.prefix(length).lowercased() + word.dropFirst(length)
}

private let specifier = try! NSRegularExpression(
    pattern: #"%(?:([0-9]+)\$)?(?:#@([^@]+)@|[-+#0]*(?:[0-9]+|\*)?(?:\.(?:[0-9]+|\*)?)?(hh|h|ll|l|q|L|z|t|j)?([@dDiuUxXoOcCfFeEgGaAsSp%]))"#
)

/// Swift types of the format arguments of one text, by their position.
private func parameters(
    in text: String, substitutions: [String: Catalog.Substitution]
) throws -> [Int: String] {
    var types: [Int: String] = [:]
    var next = 1
    var pluralArguments: Set<String> = []
    let matches = specifier.matches(in: text, range: NSRange(text.startIndex..., in: text))
    try checkForUnreadableSpecifiers(in: text, parsed: matches.map { Range($0.range, in: text)! })
    for match in matches {
        let group = { (index: Int) in Range(match.range(at: index), in: text).map { String(text[$0]) } }
        if group(4) == "%" { continue }
        let whole = group(0)!
        if whole.contains("*") {
            throw UnsupportedKey(reason: "\(whole) takes its width or precision from an argument")
        }

        var explicitPosition = group(1)
        let type: String
        if let name = group(2) {
            guard let substitution = substitutions[name] else {
                throw UnsupportedKey(reason: "substitution \(name) is missing")
            }
            pluralArguments.insert(name)
            let specifier = substitution.formatSpecifier
            type = try swiftType(conversion: String(specifier.suffix(1)), length: String(specifier.dropLast()))
            if explicitPosition == nil, let argNum = substitution.argNum { explicitPosition = String(argNum) }
        } else {
            type = try swiftType(conversion: group(4)!, length: group(3) ?? "")
        }

        let position: Int
        if let explicitPosition {
            guard let explicit = Int(explicitPosition), (1...100).contains(explicit) else {
                throw UnsupportedKey(reason: "\(whole) has an invalid argument position")
            }
            position = explicit
        } else {
            position = next
            next += 1
        }
        if let existing = types[position], existing != type {
            throw UnsupportedKey(reason: "argument \(position) is \(existing) in one place and \(type) in another")
        }
        types[position] = type
    }
    if pluralArguments.count > 1 {
        throw UnservableKey(
            reason: "it has \(pluralArguments.count) plural arguments (\(pluralArguments.sorted().joined(separator: ", "))) "
                + "and the CDN delivers a single plural per key")
    }
    return types
}

/// A `%` the specifier pattern did not accept is plain text when a space, punctuation or the end of the text
/// follows it ("50% off", "Save 20%!"). When a letter, digit or specifier character follows, it is a specifier
/// the generator can't read, such as `%1$1$ld`. Foundation reads such a sequence in its own way, so a member
/// generated from the readable specifiers alone would silently take the wrong parameters.
private func checkForUnreadableSpecifiers(in text: String, parsed: [Range<String.Index>]) throws {
    for index in text.indices where text[index] == "%" && !parsed.contains(where: { $0.contains(index) }) {
        let next = text.index(after: index)
        guard next < text.endIndex, text[next].isLetter || text[next].isNumber || "$.-+#".contains(text[next])
        else { continue }
        var sequence = String(
            text[index...].prefix(while: { $0.isASCII && ($0.isLetter || $0.isNumber || "%$.-+#@".contains($0)) }).prefix(12))
        while let last = sequence.last, ".-+#$".contains(last) { sequence.removeLast() }
        throw UnsupportedKey(reason: "\(sequence) can't be read as a format specifier")
    }
}

/// Integer specifiers map to `Int` / `UInt` whatever their length modifier. `%d` is very common in
/// catalogs migrated from `.strings`, and `Int32` would force `Int32(count)` at every call site and
/// make a key unusable as soon as one language writes `%d` where another writes `%lld`. On Apple's
/// 64-bit platforms `String(format:)` reads the low 32 bits of an `Int` for `%d`, which is exactly
/// what string keys do today.
private func swiftType(conversion: String, length: String) throws -> String {
    switch conversion {
    case "@": return "String"
    case "f", "F", "e", "E", "g", "G", "a", "A": return "Double"
    case "d", "i", "D": return "Int"
    case "u", "x", "X", "o", "U", "O": return "UInt"
    case "c": return "Int32"
    case "C": return "UInt16"
    default: throw UnsupportedKey(reason: "%\(conversion) can't be passed safely from Swift, use %@ instead")
    }
}

private func literal(_ string: String) -> String {
    var result = "\""
    for scalar in string.unicodeScalars {
        switch scalar {
        case "\\": result += "\\\\"
        case "\"": result += "\\\""
        case "\n": result += "\\n"
        case "\r": result += "\\r"
        case "\t": result += "\\t"
        case _ where [.control, .lineSeparator, .paragraphSeparator].contains(scalar.properties.generalCategory):
            result += "\\u{\(String(scalar.value, radix: 16))}"
        default: result.unicodeScalars.append(scalar)
        }
    }
    return result + "\""
}

private func withoutControlCharacters(_ line: Substring) -> String {
    String(String.UnicodeScalarView(line.unicodeScalars.map { $0.properties.generalCategory == .control ? " " : $0 }))
}
