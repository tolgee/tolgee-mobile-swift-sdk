import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

/// Protocol for observing app lifecycle events
protocol AppLifecycleObserverProtocol: Sendable {
    func startObserving(target: AnyObject, selector: Selector)
    func stopObserving(target: AnyObject)
}

/// Default implementation using NotificationCenter
final class AppLifecycleObserver: AppLifecycleObserverProtocol, @unchecked Sendable {
    func startObserving(target: AnyObject, selector: Selector) {
        #if canImport(UIKit)
            NotificationCenter.default.addObserver(
                target,
                selector: selector,
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        #endif

        #if canImport(AppKit)
            NotificationCenter.default.addObserver(
                target,
                selector: selector,
                name: NSApplication.willBecomeActiveNotification,
                object: nil
            )
        #endif
    }

    func stopObserving(target: AnyObject) {
        NotificationCenter.default.removeObserver(target)
    }
}
