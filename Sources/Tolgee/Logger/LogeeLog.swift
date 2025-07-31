import OSLog

final class TolgeeLog: Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: false)
    private let logger = Logger(subsystem: "com.tolgee.sdk", category: "tolgee")

    var enableDebugLogs: Bool {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }

    func debug(_ message: String) {
        if enableDebugLogs {
            logger.debug("Tolgee: \(message)")
        }
    }

    func error(_ message: String) {
        logger.error("Tolgee: \(message)")
    }
}
