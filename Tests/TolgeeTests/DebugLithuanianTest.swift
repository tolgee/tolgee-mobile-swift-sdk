import Foundation
import Testing

@testable import Tolgee

@Test func debugLithuanianActualBehavior() throws {
    let lithuanianLocale = Locale(identifier: "lt")
    let rules = PluralRules.pluralRules(for: lithuanianLocale)

    let testNumbers: [Double] = [1.0, 1.1, 2.0, 2.5, 21.0, 21.1, 0.5, 10.1]

    for number in testNumbers {
        let result = rules.category(for: number)
        print("\(number): \(result)")
    }
}
