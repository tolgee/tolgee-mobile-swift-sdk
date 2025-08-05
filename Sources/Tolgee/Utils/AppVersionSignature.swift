import Foundation

internal func getAppVersionSignature() -> String? {
    guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        return nil
    }
    guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
        return nil
    }
    return "\(version)-\(build)"
}
