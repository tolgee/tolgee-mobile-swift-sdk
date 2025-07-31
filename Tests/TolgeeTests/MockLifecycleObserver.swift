import Foundation

@testable import Tolgee

/// Mock lifecycle observer for testing the closure-based approach
final class MockLifecycleObserver: AppLifecycleObserverProtocol, @unchecked Sendable {
    private var foregroundCallback: (@MainActor () -> Void)?
    private var isObserving = false

    func startObserving(onForeground: @escaping @MainActor () -> Void) {
        foregroundCallback = onForeground
        isObserving = true
    }

    func stopObserving() {
        foregroundCallback = nil
        isObserving = false
    }

    /// Simulate the app entering foreground - useful for testing
    func simulateAppEnteringForeground() {
        guard isObserving else { return }
        Task { @MainActor in
            foregroundCallback?()
        }
    }

    /// Check if observer is currently active
    var isCurrentlyObserving: Bool {
        return isObserving
    }
}
