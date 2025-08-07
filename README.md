# Tolgee iOS SDK

[![CI](https://github.com/petrpavlik/tolgee-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/petrpavlik/tolgee-ios/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/petrpavlik/tolgee-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/petrpavlik/tolgee-ios)

A modern iOS SDK for [Tolgee](https://tolgee.io) - the developer-friendly localization platform.

## Features

- 🌍 **Remote translation loading** from Tolgee CDN
- 📦 **Namespace-based organization** for better translation management  
- 💾 **Automatic caching** with background updates
- 🔄 **Fallback support** to bundle-based localizations
- 🎯 **Automatic language detection** from device settings
- ⚡ **Async/await support** for modern Swift development
- 🧪 **ICU plural forms** support
- 🔧 **SwiftUI integration** with reactive updates

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/petrpavlik/tolgee-ios", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/petrpavlik/tolgee-ios`

## Quick Start

```swift
import Tolgee

// Initialize Tolgee with your CDN URL
let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
Tolgee.shared.initialize(cdn: cdnURL)

// Fetch latest translations
await Tolgee.shared.remoteFetch()

// Use translations in your app
let greeting = Tolgee.shared.translate("hello_world")
let personalGreeting = Tolgee.shared.translate("hello_name", "Alice")
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.7+
- Xcode 14.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
