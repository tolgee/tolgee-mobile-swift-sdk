import Combine

/// A SwiftUI-compatible observable object that automatically triggers re-renders of your SwiftUI hierarchy when translations change.
///
/// Use this class with SwiftUI views to ensure they automatically update when Tolgee translations are modified or reloaded.
/// Simply inject this as an `@ObservedObject` or `@StateObject` in your SwiftUI views that display translated content.
///
/// Example usage:
/// ```swift
/// @main
/// struct MyApp: App {
///     @StateObject private var tolgeeUpdater = TolgeeSwiftUIUpdater()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environmentObject(tolgeeUpdater)
///         }
///     }
/// }
/// ```
@MainActor
public final class TolgeeSwiftUIUpdater: ObservableObject {

    public init() {
        self.objectWillChange.send()
    }
}
