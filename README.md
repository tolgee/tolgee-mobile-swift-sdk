# Tolgee Mobile Swift SDK (Alpha) 🐁

[![Tolgee](https://img.shields.io/badge/Tolgee-f06695)](https://tolgee.io/)
![Android](https://img.shields.io/badge/Android-Supported-green?logo=android)
![language](https://img.shields.io/github/languages/top/tolgee/tolgee-mobile-kotlin-sdk)
[![github release](https://img.shields.io/github/v/release/tolgee/tolgee-mobile-kotlin-sdk?label=GitHub%20Release)](https://github.com/tolgee/tolgee-mobile-kotlin-sdk/releases/latest)
[![licence](https://img.shields.io/badge/license-Apache%202%20-blue)](https://github.com/tolgee/tolgee-mobile-kotlin-sdk/blob/master/LICENSE)
[![github stars](https://img.shields.io/github/stars/tolgee/tolgee-mobile-kotlin-sdk?style=social&label=Tolgee%20Mobile%20Kotlin%20SDK)](https://github.com/tolgee/tolgee-mobile-kotlin-sdk)
[![github stars](https://img.shields.io/github/stars/tolgee/tolgee-platform?style=social&label=Tolgee%20Platform)](https://github.com/tolgee/tolgee-platform)
[![Github discussions](https://img.shields.io/github/discussions/tolgee/tolgee-platform)](https://github.com/tolgee/tolgee-platform/discussions)
[![Dev.to](https://img.shields.io/badge/Dev.to-tolgee_i18n?logo=devdotto&logoColor=white)](https://dev.to/tolgee_i18n)
[![Read the Docs](https://img.shields.io/badge/Read%20the%20Docs-8CA1AF?logo=readthedocs&logoColor=fff)](https://docs.tolgee.io/)
[![Slack](https://img.shields.io/badge/Slack-4A154B?logo=slack&logoColor=fff)](https://tolg.ee/slack)
[![YouTube](https://img.shields.io/badge/YouTube-%23FF0000.svg?logo=YouTube&logoColor=white)](https://www.youtube.com/@tolgee)
[![LinkedIn](https://custom-icon-badges.demolab.com/badge/LinkedIn-0A66C2?logo=linkedin-white&logoColor=fff)](https://www.linkedin.com/company/tolgee/)
[![X](https://img.shields.io/badge/X-%23000000.svg?logo=X&logoColor=white)](https://x.com/Tolgee_i18n)

## What is Tolgee?

[Tolgee](https://tolgee.io/) is a powerful localization platform that simplifies the translation process for your applications.
This SDK provides integration for Kotlin-based projects, with a primary focus on Android.

Currently, Android is fully supported, but any Kotlin-based codebase can in theory use this library.

## Features

- **Over-the-air updates**: Update your translations without releasing a new app version


## Installation

> [!NOTE]
> For managing static translations (used as fallback), check out [tolgee-cli](https://github.com/tolgee/tolgee-cli).
> It provides tools for updating and syncing your static translation files.
>
> In each demo project you can find an example of `.tolgeerc` configuration file.



## 🚀 Quick Start

Here's a quick example of initializing Tolgee in an iOS application:

```swift
import Tolgee

// Initialize with your Tolgee CDN URL
let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
Tolgee.shared.initialize(cdn: cdnURL)

// Fetch latest translations asynchronously
await Tolgee.shared.remoteFetch()

// Use translations throughout your app
let greeting = Tolgee.shared.translate("hello_world")
let personalGreeting = Tolgee.shared.translate("hello_name", "Alice")
```

## ✨ Features

- 🌍 **Remote translation loading** from Tolgee CDN with automatic updates
- 📦 **Namespace-based organization** for scalable translation management  
- 💾 **Intelligent caching** with ETag support and background synchronization
- 🔄 **Automatic fallback** to bundle-based localizations when offline
- 🎯 **Smart language detection** from device settings with manual override
- ⚡ **Modern async/await API** for Swift concurrency
- 🧪 **ICU plural forms** support for complex pluralization rules
- 🔧 **SwiftUI integration** with reactive updates and `TolgeeText` component
- 📱 **Multi-platform support** for iOS, macOS, tvOS, and watchOS
- 🏗️ **Type-safe** and performant with strict concurrency
- 🔍 **Advanced debugging** with comprehensive logging
- 🎨 **String interpolation** with format specifiers and multiple arguments

## 📦 Installation

### Swift Package Manager (Recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/petrpavlik/tolgee-ios", from: "1.0.0")
]
```

Or through Xcode:
1. File → Add Package Dependencies...
2. Enter: `https://github.com/petrpavlik/tolgee-ios`
3. Choose version and add to your target

## 🎯 Basic Usage

### Initialization

```swift
import Tolgee

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Basic initialization with automatic language detection
        let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
        Tolgee.shared.initialize(cdn: cdnURL)
        
        // Optional: Fetch translations immediately
        Task {
            await Tolgee.shared.remoteFetch()
        }
        
        return true
    }
}
```

### Advanced Initialization

```swift
// Initialize with specific language and namespaces
Tolgee.shared.initialize(
    cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!,
    language: "es", // Force Spanish instead of auto-detection
    namespaces: ["buttons", "errors", "onboarding"], // Organize translations
    enableDebugLogs: true // Enable detailed logging for development
)
```

### Basic Translation

```swift
// Simple string translation
let title = Tolgee.shared.translate("app_title")

// Translation with arguments
let welcomeMessage = Tolgee.shared.translate("welcome_user", "John")
let itemCount = Tolgee.shared.translate("items_count", 5)

// Translation from specific namespace/table
let saveButton = Tolgee.shared.translate("save", table: "buttons")
```

### Plural Forms & ICU Support

```swift
// Automatic plural form selection based on count
let appleCount1 = Tolgee.shared.translate("apple_count", 1)    // "You have 1 apple"
let appleCount5 = Tolgee.shared.translate("apple_count", 5)    // "You have 5 apples"

// Complex pluralization for different languages
let czechPlural = Tolgee.shared.translate("items_count", 2.5)  // Handles Czech plural rules
```

## 🔧 SwiftUI Integration

### TolgeeText Component

```swift
import SwiftUI
import Tolgee

struct ContentView: View {
    @State private var userName = "Alice"
    @State private var itemCount = 5
    
    var body: some View {
        VStack {
            // Simple text translation
            TolgeeText("welcome_title")
                .font(.largeTitle)
            
            // Text with arguments
            TolgeeText("hello_user", userName)
                .foregroundColor(.blue)
            
            // Text with pluralization
            TolgeeText("item_count", itemCount)
            
            // Text from specific table/namespace
            TolgeeText("save", tableName: "buttons")
        }
    }
}
```

### Reactive Updates

```swift
struct TranslationView: View {
    @State private var translationText = ""
    
    var body: some View {
        Text(translationText)
            .task {
                // Listen for translation updates
                for await _ in Tolgee.shared.onTranslationsUpdated() {
                    translationText = Tolgee.shared.translate("dynamic_content")
                }
            }
            .onAppear {
                // Initial translation
                translationText = Tolgee.shared.translate("dynamic_content")
            }
    }
}
```

## 🌐 Advanced Features

### Namespace Management

```swift
// Initialize with multiple namespaces for better organization
Tolgee.shared.initialize(
    cdn: cdnURL,
    namespaces: ["common", "auth", "profile", "settings"]
)

// Use translations from specific namespaces
let commonGreeting = Tolgee.shared.translate("hello", table: "common")
let authError = Tolgee.shared.translate("invalid_credentials", table: "auth")
let profileTitle = Tolgee.shared.translate("edit_profile", table: "profile")
```

### Background Updates

```swift
class TranslationManager {
    func setupPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await Tolgee.shared.remoteFetch()
                print("Translations updated at \(Date())")
            }
        }
    }
}
```

### Translation Status Monitoring

```swift
// Check initialization status
if Tolgee.shared.isInitialized {
    print("Tolgee is ready to use")
}

// Check last fetch timestamp
if let lastFetch = Tolgee.shared.lastFetchDate {
    print("Last update: \(lastFetch)")
} else {
    print("No remote fetch performed yet")
}
```

### Offline-First with Fallbacks

```swift
// Tolgee automatically falls back to bundle-based localizations
// when remote translations are unavailable

// 1. First tries remote translations from CDN
// 2. Falls back to cached translations
// 3. Finally falls back to bundle-based Localizable.strings

let text = Tolgee.shared.translate("offline_message") // Always works
```

## 📱 Platform Support

| Platform | Minimum Version | 
|----------|----------------|
| iOS      | 16.0+          |
| macOS    | 13.0+          |
| tvOS     | 16.0+          |
| watchOS  | 6.0+           |

## ⚙️ Requirements

- **Swift:** 6.0+
- **Xcode:** 15.0+

## 🤝 Why Choose Tolgee?

**Tolgee saves a lot of time** you would spend on localization tasks otherwise. It enables you to provide **perfectly translated software**.

### All-in-one localization solution for your iOS application 🙌
### Out-of-box in-context localization 🎉  
### Automated screenshot generation 📷
### Translation management platform 🎈
### Open-source 🔥

[Learn more on the Tolgee website →](https://tolgee.io)

## 📚 Examples & Demos

Check out our example projects:
- [Basic iOS App](examples/basic-ios)
- [SwiftUI Integration](examples/swiftui-demo)
- [Multi-platform App](examples/multiplatform)

## 🆘 Need Help?

- 📖 [Documentation](https://docs.tolgee.io)
- 💬 [Community Discord](https://discord.gg/tolgee)
- 🐛 [Report Issues](https://github.com/petrpavlik/tolgee-ios/issues)
- 💡 [Feature Requests](https://github.com/petrpavlik/tolgee-ios/discussions)

## 🏗️ Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <a href="https://tolgee.io">
    <img src="https://user-images.githubusercontent.com/18496315/188628892-33fcc282-44f1-4926-8be4-d0db5a2420ca.png" alt="Tolgee" />
  </a>
</p>

<p align="center">
Made with ❤️ by the <a href="https://github.com/tolgee">Tolgee team</a>
</p>
