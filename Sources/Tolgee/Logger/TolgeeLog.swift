import OSLog

@MainActor
final class TolgeeLog {
    private let logger = Logger(subsystem: "com.tolgee.sdk", category: "tolgee")
    private var onLogMessageSubscribers = [ContinuationWrapper<LogMessage>]()

    var enableDebugLogs: Bool = false

    func onLogMessage() -> AsyncStream<LogMessage> {
        AsyncStream<LogMessage> { continuation in
            let wrapper = ContinuationWrapper<LogMessage>(continuation: continuation)

            onLogMessageSubscribers.append(wrapper)

            // Handle termination
            continuation.onTermination = { [weak self] reason in
                DispatchQueue.main.async { [weak self] in
                    wrapper.markDead()
                    self?.onLogMessageSubscribers.removeAll { !$0.isAlive }
                }
            }
        }
    }

    private func log(_ level: OSLogType, message: String) {
        let timestamp = Date()
        let logMessage = LogMessage(level: level, message: message, timestamp: timestamp)

        // Notify all subscribers
        for subscriber in onLogMessageSubscribers {
            subscriber.yield(logMessage)
        }

        // Log to system logger
        logger.log(level: level, "Tolgee: \(message)")
    }

    func debug(_ message: String) {
        if enableDebugLogs {
            log(.debug, message: message)
        }
    }

    func error(_ message: String) {
        log(.error, message: message)
        logger.error("Tolgee: \(message)")
    }

    func info(_ message: String) {
        log(.info, message: message)
    }

}
