import Foundation
import TolgeeKeysGeneratorCore

/// Usage: TolgeeKeysGenerator <input.xcstrings> <table> <output.swift>
///
/// Problems are printed as `<file>: warning: …` / `<file>: error: …`, so Xcode shows them on the catalog.
@main
struct TolgeeKeysGeneratorTool {
    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 4 else {
            fail("Usage: TolgeeKeysGenerator <input.xcstrings> <table> <output.swift>")
        }
        let input = arguments[1]
        let output = URL(fileURLWithPath: arguments[3])
        do {
            let result = try generateKeys(catalog: Data(contentsOf: URL(fileURLWithPath: input)), table: arguments[2])
            for warning in result.warnings {
                print("\(input): warning: \(warning)")
            }
            if (try? String(contentsOf: output, encoding: .utf8)) != result.code {
                try result.code.write(to: output, atomically: true, encoding: .utf8)
            }
        } catch {
            fail("\(input): error: \(error)")
        }
    }

    static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(1)
    }
}
