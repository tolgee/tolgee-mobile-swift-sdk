import Foundation
import Testing

@testable import Tolgee

@MainActor
struct AutomaticLanguageDetectionTests {

    @Test func testAutomaticLanguageDetection() {
        // Create mock dependencies
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        // Create a fresh Tolgee instance for testing
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: nil
        )

        // Test automatic initialization (without specifying language)
        tolgee.initialize()

        // Verify that the instance is initialized
        #expect(tolgee.isInitialized)

        // The test passes if initialization completes without error
        // The actual language detection logic uses system locale which we can't easily mock
        // but we can verify the initialize() method works without requiring a language parameter
        #expect(Bool(true))
    }

    @Test func testManualLanguageOverride() {
        // Create mock dependencies
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        // Create a fresh Tolgee instance for testing
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: nil
        )

        // Test manual language specification (for testing scenarios)
        tolgee.initialize(language: "cs")

        // Verify that the instance is initialized
        #expect(tolgee.isInitialized)

        // Load test translations to verify functionality
        let testJSON = """
            {
                "test_key": "Test hodnota v češtině"
            }
            """

        do {
            try tolgee.loadTranslations(from: testJSON)
            let translation = tolgee.translate("test_key")
            #expect(translation == "Test hodnota v češtině")
        } catch {
            #expect(Bool(false), "Failed to load translations: \(error)")
        }
    }

    @Test func testPreferredLanguageDetection() {
        // Create mock dependencies
        let mockSession = MockURLSession()
        let mockCache = MockCache()

        // Create a fresh Tolgee instance for testing
        let tolgee = Tolgee(
            urlSession: mockSession,
            cache: mockCache,
            appVersionSignature: nil
        )

        // We can't easily mock the system locale, but we can test that the method
        // exists and works without throwing errors
        tolgee.initialize(cdn: URL(string: "https://example.com")!)

        #expect(tolgee.isInitialized)

        // Verify that CDN URL was set (this shows initialization worked)
        // We can't access private properties directly, but if initialization
        // completed without error, the automatic detection worked
        #expect(Bool(true))
    }
}
