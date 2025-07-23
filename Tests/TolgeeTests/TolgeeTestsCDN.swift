import Foundation
import Testing

@testable import Tolgee

@MainActor
struct TolgeeTestsCDN {

    let cdnURL = URL(string: "https://cdn.tolg.ee/60ffdb64294ad33e0cc5076cfa71efe2")!
    let locale = Locale(identifier: "cs")

    @Test func testCDNInitialization() async throws {
        if #available(macOS 15.4, *) {
            let tolgee = Tolgee.shared

            // Initialize with CDN URL
            tolgee.initialize(cdn: cdnURL, language: "cs")

            // Give some time for the async fetch to complete
            try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds

            // Test that translations were loaded from CDN
            let simpleString = tolgee.translate("Hello, world!", locale: locale)
            #expect(simpleString == "Ahoj světe!")

            let parametrizedString = tolgee.translate("My name is %@", "Petr", locale: locale)
            #expect(parametrizedString == "Jmenuji se Petr")

            #expect(tolgee.translate("I have %lld apples", 0, locale: locale) == "Mám 0 jablek")
            #expect(tolgee.translate("I have %lld apples", 1, locale: locale) == "Mám 1 jablko")
            #expect(tolgee.translate("I have %lld apples", 2, locale: locale) == "Mám 2 jablka")
            #expect(tolgee.translate("I have %lld apples", 3, locale: locale) == "Mám 3 jablka")
            #expect(tolgee.translate("I have %lld apples", 4, locale: locale) == "Mám 4 jablka")
            #expect(tolgee.translate("I have %lld apples", 5, locale: locale) == "Mám 5 jablek")
        } else {
            #expect(false)
        }
    }
}
