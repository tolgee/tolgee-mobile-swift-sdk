import Foundation

// MARK: - Extension for Bundle method swizzling.
extension Bundle {
    @MainActor
    static var original: Method!

    @MainActor
    static var swizzled: Method!

    @MainActor
    static var isSwizzled: Bool {
        return original != nil && swizzled != nil
    }

    /// Swizzled implementation for localizedString(forKey:value:table:) method.
    ///
    /// - Parameters:
    ///   - key: The key for a string in the table identified by tableName.
    ///   - value: The value to return if key is nil or if a localized string for key can’t be found in the table.
    ///   - tableName: The receiver’s string table to search. If tableName is nil or is an empty string, the method attempts to use the table in Localizable.strings.
    /// - Returns: Localization value for localization key provided by crowdin. If there are no string for provided localization key, localization string from bundle will be returned.
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
        // swiftlint:disable force_unwrapping
        original = class_getInstanceMethod(
            self, #selector(Bundle.localizedString(forKey:value:table:)))!
        swizzled = class_getInstanceMethod(
            self, #selector(Bundle.swizzled_LocalizedString(forKey:value:table:)))!
        method_exchangeImplementations(original, swizzled)
    }

    @MainActor
    class func unswizzle() {
        guard original != nil && swizzled != nil else { return }
        method_exchangeImplementations(swizzled, original)
        swizzled = nil
        original = nil
    }
}
