import Foundation

@MainActor
final class ContinuationWrapper<T: Sendable> {
    let continuation: AsyncStream<T>.Continuation
    let id: UUID
    var isAlive: Bool = true
    let createdAt: Date

    init(continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
        self.id = UUID()
        self.createdAt = Date()
    }

    func yield(_ value: T) {
        guard isAlive else {
            return
        }
        continuation.yield(value)
    }

    func finish() {
        isAlive = false
        continuation.finish()
    }

    func markDead() {
        isAlive = false
    }
}
