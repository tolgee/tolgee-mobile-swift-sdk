import Foundation
import Testing

@testable import Tolgee

@MainActor
struct TolgeeTestsCDN {

    let cdnURL = URL(string: "https://cdntest.tolg.ee/47b95b14388ff538b9f7159d0daf92d2")!
    let locale = Locale(identifier: "cs")

    @Test func testCDNInitializationWithMock() async throws {
        if #available(macOS 15.4, *) {
            // Create mock URL session
            let mockSession = MockURLSession()

            // Set up mock responses
            let baseURL = cdnURL.appending(component: "cs.json")
            let namespaceURL = cdnURL.appending(component: "Localizable2/cs.json")

            try await mockSession.setMockJSONResponse(
                for: baseURL,
                json: [
                    "Hello, world!": "Ahoj světe!",
                    "My name is %@": "Jmenuji se %@",
                    "I have %lld apples": [
                        "variations": [
                            "plural": [
                                "one": "Mám %lld jablko",
                                "few": "Mám %lld jablka",
                                "other": "Mám %lld jablek",
                            ]
                        ]
                    ],
                ])

            try await mockSession.setMockJSONResponse(
                for: namespaceURL,
                json: [
                    "Namespace test": "Test jmenného prostoru"
                ])

            // Create Tolgee instance with mock session
            let tolgee = Tolgee(
                urlSession: mockSession,
                cache: MockCache(),
                appVersionSignature: nil
            )

            // Initialize with CDN URL
            tolgee.initialize(cdn: cdnURL, language: "cs", namespaces: ["Localizable2"])

            // Explicitly fetch translations from CDN
            try await tolgee.remoteFetch()

            // Test that translations were loaded from mocked CDN
            let simpleString = tolgee.translate("Hello, world!", locale: locale)
            #expect(simpleString == "Ahoj světe!")

            let parametrizedString = tolgee.translate("My name is %@", "Petr", locale: locale)
            #expect(parametrizedString == "Jmenuji se Petr")

            #expect(tolgee.translate("I have %lld apples", 0, locale: locale) == "Mám 0 jablek")
            #expect(tolgee.translate("I have %lld apples", 1, locale: locale) == "Mám 1 jablko")
            #expect(tolgee.translate("I have %lld apples", 2, locale: locale) == "Mám 2 jablka")
            #expect(tolgee.translate("I have %lld apples", 5, locale: locale) == "Mám 5 jablek")

            // Verify the URLs were requested
            let requestedURLs = await mockSession.requestedURLs
            #expect(requestedURLs.contains(baseURL))
            #expect(requestedURLs.contains(namespaceURL))
        } else {
            throw TolgeeError.translationNotFound
        }
    }

    @Test func testCDNInitialization() async throws {
        if #available(macOS 15.4, *) {
            let tolgee = Tolgee.shared

            // Initialize with CDN URL
            tolgee.initialize(cdn: cdnURL, language: "cs", namespaces: ["Localizable2"])

            // Explicitly fetch translations from CDN
            try await tolgee.remoteFetch()

            // Test that translations were loaded from CDN
            let simpleString = tolgee.translate("Hello, world!", locale: locale)
            #expect(simpleString == "Ahoj, světe!")

            let parametrizedString = tolgee.translate("My name is %@", "Petr", locale: locale)
            #expect(parametrizedString == "Jmenuji se Petr")

            #expect(tolgee.translate("I have %lld apples", 0, locale: locale) == "Mám 0 jablek")
            #expect(tolgee.translate("I have %lld apples", 1, locale: locale) == "Mám 1 jablko")
            #expect(tolgee.translate("I have %lld apples", 2, locale: locale) == "Mám 2 jablka")
            #expect(tolgee.translate("I have %lld apples", 3, locale: locale) == "Mám 3 jablka")
            #expect(tolgee.translate("I have %lld apples", 4, locale: locale) == "Mám 4 jablka")
            #expect(tolgee.translate("I have %lld apples", 5, locale: locale) == "Mám 5 jablek")
        } else {
            throw TolgeeError.translationNotFound
        }
    }
}
