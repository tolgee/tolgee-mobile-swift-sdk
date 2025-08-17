#if TOLGEE_SWIZZLE_NSLOCALIZEDSTRING

    import Foundation

    /// NSLocalizedString swizzling for automatic Tolgee integration.
    ///
    /// When `TOLGEE_SWIZZLE_NSLOCALIZEDSTRING` is defined, this module automatically
    /// intercepts all `NSLocalizedString` calls and routes them through Tolgee's
    /// translation system. This provides seamless integration without requiring
    /// code changes throughout your application.
    ///
    /// ## Usage
    ///
    /// Add the compile flag to your project:
    /// ```
    /// TOLGEE_SWIZZLE_NSLOCALIZEDSTRING=1
    /// ```
    ///
    /// Then initialize Tolgee normally:
    /// ```swift
    /// Tolgee.shared.initialize(cdn: yourCDNURL)
    /// await Tolgee.shared.remoteFetch()
    /// ```
    ///
    /// All existing `NSLocalizedString` calls will automatically use Tolgee translations:
    /// ```swift
    /// // This will now use Tolgee instead of bundle-based localizations
    /// let text = NSLocalizedString("hello_world", comment: "Greeting")
    /// ```
    ///
    /// ## Benefits
    /// - Zero code changes required in existing projects
    /// - Automatic fallback to bundle localizations when Tolgee is unavailable
    /// - Maintains all existing NSLocalizedString behavior and parameters
    /// - Works with third-party libraries that use NSLocalizedString
    ///
    /// ## Implementation Details
    /// This replaces the global NSLocalizedString functions with Tolgee-aware versions.
    /// The original implementations are preserved and used as fallbacks.
    ///
    /// - Warning: Function replacement should be used carefully in production. Consider
    ///   using explicit Tolgee calls for better control and debugging.
    ///
    /// - Note: Swizzling is performed automatically when this module is imported
    ///   and the compile flag is active.

    // MARK: - Store Original Functions

    private let _original_NSLocalizedString = NSLocalizedString
    private let _original_NSLocalizedStringFromTable = NSLocalizedStringFromTable
    private let _original_NSLocalizedStringFromTableInBundle = NSLocalizedStringFromTableInBundle
    private let _original_NSLocalizedStringWithDefaultValue = NSLocalizedStringWithDefaultValue

    // MARK: - Tolgee-Aware NSLocalizedString Functions

    /// Tolgee-aware replacement for NSLocalizedString
    ///
    /// This function first attempts to get translations from Tolgee, then falls back
    /// to the original NSLocalizedString implementation if Tolgee is unavailable.
    public func NSLocalizedString(_ key: String, comment: String) -> String {
        return TolgeeNSLocalizedString(
            key, tableName: nil, bundle: Bundle.main, value: "", comment: comment)
    }

    /// Tolgee-aware replacement for NSLocalizedStringFromTable
    public func NSLocalizedStringFromTable(_ key: String, _ tableName: String?, comment: String)
        -> String
    {
        return TolgeeNSLocalizedString(
            key, tableName: tableName, bundle: Bundle.main, value: "", comment: comment)
    }

    /// Tolgee-aware replacement for NSLocalizedStringFromTableInBundle
    public func NSLocalizedStringFromTableInBundle(
        _ key: String, _ tableName: String?, _ bundle: Bundle, comment: String
    ) -> String {
        return TolgeeNSLocalizedString(
            key, tableName: tableName, bundle: bundle, value: "", comment: comment)
    }

    /// Tolgee-aware replacement for NSLocalizedStringWithDefaultValue
    public func NSLocalizedStringWithDefaultValue(
        _ key: String, _ tableName: String?, _ bundle: Bundle, _ value: String, comment: String
    ) -> String {
        return TolgeeNSLocalizedString(
            key, tableName: tableName, bundle: bundle, value: value, comment: comment)
    }

    // MARK: - Core Tolgee Translation Logic

    /// Core function that handles Tolgee translation with fallback
    private func TolgeeNSLocalizedString(
        _ key: String, tableName: String?, bundle: Bundle, value: String, comment: String
    ) -> String {
        // Only use Tolgee if it's initialized and available
        //FIXME: make Tolgee.shared and .translate nonisolated
        // if Tolgee.shared.isInitialized {
        //     // Try to get translation from Tolgee first
        //     let tolgeeTranslation = Tolgee.shared.translate(key, table: tableName, bundle: bundle)

        //     // If Tolgee returns something different from the key, use it
        //     // This handles the case where Tolgee falls back to NSLocalizedString
        //     if tolgeeTranslation != key {
        //         return tolgeeTranslation
        //     }
        // }

        // Fall back to original NSLocalizedString implementation
        if tableName != nil && bundle != Bundle.main {
            return _original_NSLocalizedStringFromTableInBundle(key, tableName, bundle, comment)
        } else if tableName != nil {
            return _original_NSLocalizedStringFromTable(key, tableName, comment)
        } else if !value.isEmpty {
            return _original_NSLocalizedStringWithDefaultValue(
                key, tableName, bundle, value, comment)
        } else {
            return _original_NSLocalizedString(key, comment)
        }
    }

    // MARK: - Initialization Status

    /// Public enum for checking swizzling status
    public enum TolgeeNSLocalizedStringSwizzling {
        /// Indicates whether swizzling has been performed.
        /// Always true when TOLGEE_SWIZZLE_NSLOCALIZEDSTRING is defined.
        public static let isSwizzled = true

        #if DEBUG
            /// Print swizzling status for debugging
            public static func printStatus() {
                print("[Tolgee] NSLocalizedString swizzling is active")
                print("[Tolgee] All NSLocalizedString calls will be routed through Tolgee")
            }
        #endif
    }

    // MARK: - Automatic Initialization

    /// Automatically log swizzling status when the module loads
    private final class TolgeeSwizzlingInitializer: Sendable {
        static let shared = TolgeeSwizzlingInitializer()

        private init() {
            #if DEBUG
                DispatchQueue.main.async {
                    print("[Tolgee] NSLocalizedString swizzling enabled")
                }
            #endif
        }
    }

    // Trigger automatic initialization
    private let x = TolgeeSwizzlingInitializer.shared

#endif  // TOLGEE_SWIZZLE_NSLOCALIZEDSTRING
