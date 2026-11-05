import Foundation

/// A translation key together with its table, arguments and the bundle of its String Catalog.
///
/// Usually you don't create it yourself. `TolgeeKeysPlugin` generates a static member for every key
/// in your String Catalogs, so a typo in a key name or a wrong argument fails the build:
/// ```swift
/// TolgeeText(.homeGreeting("Jana"))
/// let title = Tolgee.shared.translate(.homeTitle)
/// ```
///
/// `TolgeeKey` is not `Equatable` or `Hashable`: its arguments hold values of any `CVarArg` type, which
/// can't be compared in a clean way.
public struct TolgeeKey: Sendable {
    // Internal on purpose: only `translate(_:)` and `TolgeeText` read these, so their shape can change
    // without a breaking change. The initializer is the only public contract, and generated code is
    // rewritten by the plugin on every build, so it can evolve together with the generator.
    let key: String
    let table: String?
    let arguments: [any CVarArg & Sendable]
    let bundle: Bundle

    /// Creates a key by hand. Prefer the members `TolgeeKeysPlugin` generates: they call this initializer
    /// for you, and its parameters may change together with the generator.
    public init(
        _ key: String, table: String? = nil, arguments: [any CVarArg & Sendable] = [], bundle: Bundle = .main
    ) {
        self.key = key
        self.table = table
        self.arguments = arguments
        self.bundle = bundle
    }
}
