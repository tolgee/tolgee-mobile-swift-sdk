import Foundation
import PackagePlugin

/// Generates a `TolgeeKey` member for every key in the target's String Catalogs (`.xcstrings`).
@main
struct TolgeeKeysPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        return commands(
            for: target.sourceFiles(withSuffix: "xcstrings").map(\.url),
            tool: try context.tool(named: "TolgeeKeysGenerator").url,
            outputDirectory: context.pluginWorkDirectoryURL)
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension TolgeeKeysPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
            commands(
                for: target.inputFiles.map(\.url).filter { $0.pathExtension == "xcstrings" },
                tool: try context.tool(named: "TolgeeKeysGenerator").url,
                outputDirectory: context.pluginWorkDirectoryURL)
        }
    }
#endif

/// Info.plist and App Shortcuts catalogs are read by the system, not through Tolgee.
private let systemTables: Set = ["InfoPlist", "AppShortcuts"]

private func commands(for catalogs: [URL], tool: URL, outputDirectory: URL) -> [Command] {
    catalogs.filter { !systemTables.contains($0.deletingPathExtension().lastPathComponent) }.map { catalog in
        let table = catalog.deletingPathExtension().lastPathComponent
        let output = outputDirectory.appending(path: "TolgeeKeys+\(table).swift")
        return .buildCommand(
            displayName: "Generate Tolgee keys for \(catalog.lastPathComponent)",
            executable: tool,
            arguments: [catalog.path, table, output.path],
            inputFiles: [catalog],
            outputFiles: [output])
    }
}
