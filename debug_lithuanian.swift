import Foundation

extension Locale {
    var languageCode: String? {
        return self.identifier.components(separatedBy: "_").first
    }
}

// Minimal PluralCategory enum
enum PluralCategory: String, CaseIterable {
    case zero, one, two, few, many, other
}

// Simplified test
func lithuanianRules(n: Double, i: Int, v: Int, f: Int) -> PluralCategory {
    // n % 10 = 1 and n % 100 != 11..19
    if Int(n) % 10 == 1 && !(Int(n) % 100 >= 11 && Int(n) % 100 <= 19) {
        return .one
    }
    // n % 10 = 2..9 and n % 100 != 11..19
    if (Int(n) % 10 >= 2 && Int(n) % 10 <= 9) && !(Int(n) % 100 >= 11 && Int(n) % 100 <= 19) {
        return .few
    }
    // f != 0
    if f != 0 {
        return .many
    }
    return .other
}

let testNumbers: [Double] = [1.0, 1.1, 2.0, 2.5, 21.0, 21.1]

for number in testNumbers {
    let i = Int(number)
    let components = String(number).components(separatedBy: ".")
    let v = components.count > 1 ? components[1].count : 0
    let f = components.count > 1 ? Int(components[1]) ?? 0 : 0

    let result = lithuanianRules(n: number, i: i, v: v, f: f)
    print("\(number): i=\(i), v=\(v), f=\(f) -> \(result)")
}
