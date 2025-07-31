import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

/// Protocol for observing app lifecycle events
protocol AppLifecycleObserverProtocol: Sendable {
    func startObserving(onForeground: @escaping @MainActor () -> Void)
    func stopObserving()
}

/// Default implementation using NotificationCenter
final class AppLifecycleObserver: AppLifecycleObserverProtocol, @unchecked Sendable {
    private var observers: [NSObjectProtocol] = []

    func startObserving(onForeground: @escaping @MainActor () -> Void) {
        #if canImport(UIKit)
            let observer = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onForeground()
                }
            }
            observers.append(observer)
        #endif

        #if canImport(AppKit)
            let observer = NotificationCenter.default.addObserver(
                forName: NSApplication.willBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onForeground()
                }
            }
            observers.append(observer)
        #endif
    }

    func stopObserving() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }
}
