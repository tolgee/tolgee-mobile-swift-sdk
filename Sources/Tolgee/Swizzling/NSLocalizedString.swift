#if TOLGEE_SWIZZLE_NSLOCALIZEDSTRING

    import Foundation
    import ObjectiveC

    extension Bundle {

        @objc dynamic func tolgee_localizedString(
            forKey key: String, value: String?, table tableName: String?
        ) -> String {
            // Only use Tolgee if it's initialized and available
            if Tolgee.shared.isInitialized {
                // Try to get translation from Tolgee first
                let tolgeeTranslation = Tolgee.shared.translate(key, table: tableName, bundle: self)

                // If Tolgee returns something different from the key, use it
                // This means Tolgee found a translation and didn't fall back
                if tolgeeTranslation != key {
                    return tolgeeTranslation
                }
            }

            // Fall back to original implementation
            // This calls the original method (which is now at this selector due to swizzling)
            return tolgee_localizedString(forKey: key, value: value, table: tableName)
        }
    }

    // MARK: - Swizzling Implementation

    public enum TolgeeNSLocalizedStringSwizzling {

        /// Indicates whether swizzling has been performed.
        public private(set) static var isSwizzled = false

        /// Enable NSLocalizedString swizzling.
        ///
        /// This method is called automatically when the module loads, but can also
        /// be called manually if needed. Multiple calls are safe - swizzling will
        /// only be performed once.
        public static func enableSwizzling() {
            guard !isSwizzled else { return }

            swizzleBundleLocalizedString()

            isSwizzled = true

            #if DEBUG
                print("[Tolgee] NSLocalizedString swizzling enabled")
            #endif
        }

        private static func swizzleBundleLocalizedString() {
            let originalSelector = #selector(Bundle.localizedString(forKey:value:table:))
            let swizzledSelector = #selector(Bundle.tolgee_localizedString(forKey:value:table:))

            guard let originalClass = NSClassFromString("NSBundle") ?? Bundle.self as? AnyClass,
                let originalMethod = class_getInstanceMethod(originalClass, originalSelector),
                let swizzledMethod = class_getInstanceMethod(Bundle.self, swizzledSelector)
            else {
                #if DEBUG
                    print("[Tolgee] Failed to get methods for swizzling")
                #endif
                return
            }

            // Add the method to the target class if it doesn't exist
            let didAddMethod = class_addMethod(
                originalClass,
                originalSelector,
                method_getImplementation(swizzledMethod),
                method_getTypeEncoding(swizzledMethod)
            )

            if didAddMethod {
                // If we added the method, replace the swizzled method with the original
                class_replaceMethod(
                    originalClass,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod)
                )
            } else {
                // If the method already exists, exchange implementations
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }

            #if DEBUG
                print("[Tolgee] Bundle.localizedString method swizzled successfully")
            #endif
        }

        #if DEBUG
            /// Print swizzling status for debugging
            public static func printStatus() {
                print(
                    "[Tolgee] NSLocalizedString swizzling is \(isSwizzled ? "active" : "inactive")")
                if isSwizzled {
                    print("[Tolgee] All NSLocalizedString calls will be routed through Tolgee")
                }
            }
        #endif
    }

    // MARK: - Automatic Initialization

    /// Automatically enable swizzling when the module loads
    private final class TolgeeSwizzlingInitializer: Sendable {
        static let shared = TolgeeSwizzlingInitializer()

        private init() {
            // Perform swizzling
            TolgeeNSLocalizedStringSwizzling.enableSwizzling()
        }
    }

    // Trigger automatic initialization
    private let _ = TolgeeSwizzlingInitializer.shared

#endif  // TOLGEE_SWIZZLE_NSLOCALIZEDSTRING
