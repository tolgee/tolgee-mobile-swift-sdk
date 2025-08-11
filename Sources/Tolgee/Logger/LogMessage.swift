import OSLog

/// A structured representation of a log message with metadata.
public struct LogMessage: Sendable {
    /// The severity level of the log message.
    /// - SeeAlso: `OSLogType` for available log levels
    public var level: OSLogType

    /// The human-readable content of the log message.
    public var message: String

    /// The exact time when the log message was created.
    public var timestamp: Date
}
