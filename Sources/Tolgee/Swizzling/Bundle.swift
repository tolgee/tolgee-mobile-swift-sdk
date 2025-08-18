import Foundation

// MARK: - Extension for Bundle method swizzling.
extension Bundle {
    @MainActor
    static var original: Method!

    @MainActor
    static var swizzled: Method!

    @MainActor
    static var originalImplementation: IMP!

    @MainActor
    static var isSwizzled: Bool {
        return original != nil && swizzled != nil
    }

    @objc func swizzled_LocalizedString(
        forKey key: String, value: String?, table tableName: String?
    ) -> String {

        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                Tolgee.shared.translate(
                    key, table: tableName, bundle: self
                )
            }
        } else {
            return DispatchQueue.main.sync {
                Tolgee.shared.translate(
                    key, table: tableName, bundle: self
                )
            }
        }
    }

    @MainActor
    class func swizzle() {
        original = class_getInstanceMethod(
            self, #selector(Bundle.localizedString(forKey:value:table:)))!
        swizzled = class_getInstanceMethod(
            self, #selector(Bundle.swizzled_LocalizedString(forKey:value:table:)))!

        // Store the original implementation before swizzling
        originalImplementation = method_getImplementation(original)

        method_exchangeImplementations(original, swizzled)
    }

    @MainActor
    class func unswizzle() {
        guard original != nil && swizzled != nil else { return }
        method_exchangeImplementations(swizzled, original)
        swizzled = nil
        original = nil
        originalImplementation = nil
    }

    @MainActor
    func originalLocalizedString(
        forKey key: String, value: String? = nil, table tableName: String? = nil
    ) -> String {
        if Bundle.isSwizzled, let originalImp = Bundle.originalImplementation {
            // Call the original implementation directly using the stored function pointer
            typealias OriginalFunction = @convention(c) (
                AnyObject, Selector, NSString, NSString?, NSString?
            ) -> NSString
            let originalFunc = unsafeBitCast(originalImp, to: OriginalFunction.self)
            return originalFunc(
                self,
                #selector(Bundle.localizedString(forKey:value:table:)),
                key as NSString,
                value as NSString?,
                tableName as NSString?
            ).description
        } else {
            // If not swizzled, call the normal method
            return localizedString(forKey: key, value: value, table: tableName)
        }
    }
}
