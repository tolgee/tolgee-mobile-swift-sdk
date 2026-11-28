import Foundation
import TolgeeKeysGeneratorCore

/// Usage: TolgeeKeysGenerator <input.xcstrings> <table> <output.swift>
///
/// Problems are printed as `<file>: warning: …` / `<file>: error: …`, so Xcode shows them on the catalog. Errors
/// are printed all at once and fail the build, like the errors of Xcode's own symbol generator. Keys that get no
/// member on purpose are printed as plain lines: they belong in the build log, not in the issue navigator.
@main
struct TolgeeKeysGeneratorTool {
    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 4 else {
            fail(["Usage: TolgeeKeysGenerator <input.xcstrings> <table> <output.swift>"])
        }
        let input = arguments[1]
        let output = URL(fileURLWithPath: arguments[3])
        do {
            let result = try generateKeys(catalog: Data(contentsOf: URL(fileURLWithPath: input)), table: arguments[2])
            for warning in result.warnings {
                print("\(input): warning: \(warning)")
            }
            for note in result.notes {
                print("\(input): \(note)")
            }
            if (try? String(contentsOf: output, encoding: .utf8)) != result.code {
                try result.code.write(to: output, atomically: true, encoding: .utf8)
            }
        } catch let error as GeneratorError {
            fail(error.problems.map { "\(input): error: \($0)" })
        } catch {
            fail(["\(input): error: \(error)"])
        }
    }

    static func fail(_ lines: [String]) -> Never {
        FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
        exit(1)
    }
}
