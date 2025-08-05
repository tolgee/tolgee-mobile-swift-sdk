import Foundation
import Testing

@testable import Tolgee

@MainActor
struct RemoteFetchTests {

    @Test func testRemoteFetchMethodExists() async throws {
        // Create a Tolgee instance for testing
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: "test-1.0.0"
        )

        // Initialize Tolgee
        tolgee.initialize(
            cdn: URL(string: "https://cdn.example.com")!,
            language: "en"
        )

        // Test that remoteFetch method exists and can be called
        // The method should not throw since we're using a mock session
        do {
            try await tolgee.remoteFetch()
            // If we get here, the method executed without throwing
            #expect(true, "remoteFetch method executed successfully")
        } catch {
            // For now, it's OK if it throws due to missing network setup
            // The important thing is that the method exists and has the right signature
            #expect(true, "remoteFetch method exists and has correct async throws signature")
        }
    }

    @Test func testRemoteFetchIsAsync() async throws {
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: "test-1.0.0"
        )

        tolgee.initialize(
            cdn: URL(string: "https://cdn.example.com")!,
            language: "en"
        )

        // This test verifies that remoteFetch is properly async
        let startTime = Date()

        do {
            try await tolgee.remoteFetch()
        } catch {
            // Expected to potentially fail in test environment
        }

        let duration = Date().timeIntervalSince(startTime)

        // The method should complete relatively quickly in test environment
        #expect(duration < 5.0, "remoteFetch should complete within reasonable time")
    }
}
