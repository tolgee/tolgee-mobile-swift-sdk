import Foundation

/// A translation key together with its table, arguments and the bundle of its String Catalog.
///
/// Usually you don't create it yourself. `TolgeeKeysPlugin` generates a static member for every key
/// in your String Catalogs, so a typo in a key name or a wrong argument fails the build:
/// ```swift
/// TolgeeText(.homeGreeting("Jana"))
/// let title = Tolgee.shared.translate(.homeTitle)
/// ```
public struct TolgeeKey: Sendable {
    public let key: String
    public let table: String?
    public let arguments: [any CVarArg & Sendable]
    public let bundle: Bundle

    public init(
        _ key: String, table: String? = nil, arguments: [any CVarArg & Sendable] = [], bundle: Bundle = .main
    ) {
        self.key = key
        self.table = table
        self.arguments = arguments
        self.bundle = bundle
    }
}
