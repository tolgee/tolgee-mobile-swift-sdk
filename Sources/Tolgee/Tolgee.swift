import Combine
import Foundation

public enum TolgeeError: Error {
    case invalidJSONString
    case translationNotFound
}

/// The main Tolgee SDK class for handling localization and translations.
///
/// Tolgee provides a modern localization solution that supports:
/// - Remote translation loading from CDN
/// - Namespace-based translation organization
/// - Fallback to bundle-based localizations
/// - Automatic language detection from device settings
///
/// ## Quick Start
/// ```swift
/// // Automatic language detection (recommended for production)
/// Tolgee.shared.initialize(
///     cdn: URL(string: "https://cdn.tolgee.io/your-project-id")!
/// )
///
/// // Fetch latest translations
/// await Tolgee.shared.remoteFetch()
///
/// // Use translations in your app
/// let greeting = Tolgee.shared.translate("hello_world")
/// let personalGreeting = Tolgee.shared.translate("hello_name", "Alice")
/// ```
@MainActor
public final class Tolgee {
    /// Shared singleton instance of Tolgee for convenient access throughout your app.
    public static let shared = Tolgee(
        urlSession: URLSession(configuration: .default),
        cache: FileCache(),
        appVersionSignature: getAppVersionSignature())

    // table - [key - TranslationEntry]
    private var translations: [String: [String: TranslationEntry]] = [:]
    private var cdnEtags: [String: String] = [:]
    private var cdnURL: URL?

    private var language: String?
    private var namespaces: Set<String> = []
    private var customLocale: Locale? = nil

    /// The active locale used by the SDK.
    ///
    /// This property returns the current locale being used by the Tolgee SDK:
    /// - If a custom locale has been set via ``initialize(cdn:locale:language:namespaces:enableDebugLogs:)``
    ///   or ``setCustomLocale(_:language:)``, that locale is returned
    /// - Otherwise, returns the system's current locale (``Locale.current``)
    public var locale: Locale {
        if let customLocale {
            return customLocale
        } else {
            return Locale.current
        }
    }

    private let logger = TolgeeLog()

    private let fetchCdnService: FetchCdnService
    private let cache: CacheProtocol
    // TODO: Make bundle repository mockable for testing
    private let bundleRepository = BundleRepository()

    /// Indicates whether the Tolgee SDK has been initialized.
    ///
    /// This property becomes `true` after the first successful call to `initialize(cdn:language:namespaces:)`.
    /// Subsequent initialization attempts will be ignored while this remains `true`.
    private(set) public var isInitialized = false

    /// The timestamp of the last successful translation fetch from the CDN.
    ///
    /// This property is `nil` until the first successful CDN fetch completes. It's updated
    /// each time translations are successfully retrieved from the remote CDN, regardless
    /// of whether the translations actually changed.
    private(set) public var lastFetchDate: Date?

    private var appVersionSignature: String? = nil

    private var onTranslationsUpdatedSubscribers: [ContinuationWrapper<()>] = []
    /// A stream that allows observing when translations are updated.
    public func onTranslationsUpdated() -> AsyncStream<()> {
        AsyncStream<()> { continuation in
            let wrapper = ContinuationWrapper<()>(continuation: continuation)

            self.onTranslationsUpdatedSubscribers.append(wrapper)

            // Handle termination
            continuation.onTermination = { [weak self] reason in
                DispatchQueue.main.async { [weak self] in
                    wrapper.markDead()
                    self?.onTranslationsUpdatedSubscribers.removeAll { !$0.isAlive }
                }
            }
        }
    }

    /// Creates a stream for observing log messages emitted by the Tolgee SDK.
    public func onLogMessage() -> AsyncStream<LogMessage> {
        logger.onLogMessage()
    }

    init(
        urlSession: URLSessionProtocol, cache: CacheProtocol,
        appVersionSignature: String?
    ) {
        self.appVersionSignature = appVersionSignature
        self.fetchCdnService = FetchCdnService(urlSession: urlSession)
        self.cache = cache
    }

    /// Initializes the Tolgee SDK.
    ///
    /// This method provides flexible initialization options:
    /// - **Automatic language detection** (recommended): When `language` is `nil`, automatically detects
    ///   the user's preferred language from device settings
    /// - **Manual language specification**: When `language` is provided, uses that specific language
    ///   regardless of device settings
    ///
    /// The method loads cached translations immediately if available.
    ///
    /// - Parameters:
    ///   - cdn: The base URL of the Tolgee CDN where translation files are hosted (optional)
    ///   - locale: Optional custom locale to use for translations and formatting.
    ///   - language: The target language code on the Tolgee CDN (e.g., "en", "es", "cs"). Use this to override the locale's language when it differs from the CDN language code.
    ///   - namespaces: A set of namespace identifiers for organizing translations into logical groups (defaults to empty set)
    ///
    /// ## Usage
    /// ```swift
    /// let cdnURL = URL(string: "https://cdn.tolgee.io/your-project-id")!
    /// Tolgee.shared.initialize(cdn: cdnURL)
    /// try await Tolgee.shared.remoteFetch()
    /// ```
    public func initialize(
        cdn: URL,
        locale customLocale: Locale = .current,
        language customLanguage: String? = nil,
        namespaces: Set<String> = [],
        enableDebugLogs: Bool = false
    ) {

        guard !isInitialized else {
            logger.error("Tolgee is already initialized")
            return
        }

        logger.enableDebugLogs = enableDebugLogs

        if ProcessInfo.processInfo.environment["TOLGEE_ENABLE_SWIZZLING"] == "true" {
            logger.debug("Swizzling Bundle methods (TOLGEE_ENABLE_SWIZZLING is set to true)")
            Bundle.swizzle()
        }

        if customLanguage == nil {
            if customLocale != .current {
                // If a custom locale is provided, use its language
                if let languageCode = customLocale.language.languageCode?.identifier {
                    self.language = languageCode
                    logger.debug("Using language from custom locale: \(languageCode)")
                } else {
                    logger.error(
                        "Failed to determine language identifier from custom locale \(customLocale.identifier)"
                    )
                    return
                }
            } else {
                // I think that we'll need to extend this logic to match it with localizations available on the CDN.
                guard let preferredLanguage = Locale.preferredLanguages.first else {
                    logger.error("Failed to determine preferred language")
                    return
                }

                guard
                    let languageIdentifier = Locale(identifier: preferredLanguage).language
                        .languageCode?.identifier
                else {
                    logger.error(
                        "Failed to determine language identifier from preferred language \(preferredLanguage)"
                    )
                    return
                }
                self.language = languageIdentifier
                logger.debug("Automatically detected preferred language: \(languageIdentifier)")
            }
        } else {
            self.language = customLanguage
        }

        guard let language else {
            logger.error("Language must be specified for Tolgee initialization")
            return
        }

        cdnURL = cdn
        self.namespaces = namespaces

        if customLocale != .current {
            self.customLocale = customLocale
        }

        loadMemoryCache()

        isInitialized = true
        logger.debug("Tolgee initialized with language: \(language), namespaces: \(namespaces)")
    }

    /// Fetches the latest translations from the CDN.
    ///
    /// This method explicitly fetches translations from the configured CDN URL. By default, it fetches the current
    /// language and namespaces. It will update cached translations and notify observers when
    /// the fetch completes. You can optionally specify a different language to fetch using the language parameter.
    /// If you specify a different language than the current one, the translations will be prefetched but not applied.
    ///
    /// - Parameters:
    ///   - fetchDifferentLanguage: An optional language code to fetch different from the current one.
    ///     If provided, translations for this language will be fetched but not applied to the current state.
    /// - Note: This method requires that Tolgee has been initialized with a CDN URL.
    ///   The method will return early if these prerequisites are not met.
    public func remoteFetch(language fetchDifferentLanguage: String? = nil) async {
        guard let cdnURL, let language, language.isEmpty == false else {
            return
        }

        let languageBeingFetched = fetchDifferentLanguage ?? language

        let fetchUseCase = RemoteFetchUseCase(
            cdnURL: cdnURL,
            language: languageBeingFetched,
            namespaces: namespaces,
            appVersionSignature: appVersionSignature,
            cdnEtags: cdnEtags,
            fetchCdnService: fetchCdnService,
            cache: cache,
            logger: logger)

        do {
            let response = try await fetchUseCase()

            guard self.language == languageBeingFetched else {
                logger.debug(
                    "Language changed during fetch from \(languageBeingFetched) to \(language). Discarding fetched data."
                )
                return
            }

            try Task.checkCancellation()

            for (table, translations) in response.translations {
                self.translations[table] = translations
            }

            for (table, etag) in response.cdnEtags {
                self.cdnEtags[table] = etag
            }

            self.lastFetchDate = Date()
            self.onTranslationsUpdatedSubscribers.forEach {
                $0.yield(())
            }

        } catch {
            logger.error("Failed to fetch remote translations: \(error)")
            return
        }
    }

    /// Translates a given key to a localized string with optional format arguments.
    ///
    /// This method first attempts to find the translation in the loaded Tolgee translations,
    /// including support for ICU plural forms and format specifiers. If not found, it falls
    /// back to the bundle's localized string mechanism.
    ///
    /// - Parameters:
    ///   - key: The translation key to look up
    ///   - arguments: Variable arguments to substitute into the translated string (supports format specifiers like %@, %d, etc.)
    ///   - table: The name of the strings table to search (optional, defaults to base table)
    ///   - bundle: The bundle containing the strings file (defaults to main bundle)
    /// - Returns: The localized string for the given key with arguments formatted, or the fallback value
    ///
    /// ## Usage
    /// ```swift
    /// // Simple translation
    /// let greeting = tolgee.translate("hello_world")
    ///
    /// // Translation with arguments
    /// let personalGreeting = tolgee.translate("hello_name", "Alice")
    ///
    /// // Translation with plural forms
    /// let itemCount = tolgee.translate("item_count", 5)
    ///
    /// // Translation from specific table
    /// let buttonText = tolgee.translate("save_button", table: "Buttons")
    /// ```
    public func translate(
        _ key: String, _ arguments: CVarArg..., table: String? = nil, bundle: Bundle = .main
    )
        -> String
    {
        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key] {
            switch translationEntry {
            case .simple(let string):
                // If we have arguments, try to format the string
                if !arguments.isEmpty {
                    return String(format: string, locale: locale, arguments: arguments)
                }
                return string
            case .plural(let variants):
                let pluralRules = PluralRules(for: locale)
                if let number = arguments.compactMap({ $0 as? NSNumber }).first {
                    switch pluralRules.category(for: number.doubleValue) {
                    case .zero:
                        if let string = variants.zero {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .one:
                        if let string = variants.one {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .two:
                        if let string = variants.two {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .few:
                        if let string = variants.few {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .many:
                        if let string = variants.many {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .other:
                        if let string = variants.other {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    }
                }
            }
        }

        // Fallback to bundle.localizedString

        var bundle = bundle
        if let customLocale {
            if let replacementBundle = bundleRepository.bundle(
                for: customLocale.identifier.lowercased().replacingOccurrences(of: "_", with: "-"),
                referenceBundle: bundle)
            {
                bundle = replacementBundle
            } else {
                logger.error(
                    "No localization bundle found for locale \(customLocale.identifier) in bundle \(bundle.bundlePath)"
                )
            }
        }

        // !!! when swizzling is enabled, we use the original method to avoid infinite recursion
        let localizedString = bundle.originalLocalizedString(forKey: key, value: nil, table: table)

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return String(format: localizedString, locale: locale, arguments: arguments)
        }

        return localizedString
    }

    /// Translates a given key to a localized string with optional format arguments and custom locale.
    ///
    /// This method provides the same functionality as the basic translate method but allows you to
    /// specify a custom locale for both plural rule evaluation and bundle localization fallback.
    /// It first attempts to find the translation in the loaded Tolgee translations, including
    /// support for ICU plural forms and format specifiers. If not found, it falls back to the
    /// bundle's localized string mechanism using the specified locale.
    ///
    /// - Parameters:
    ///   - key: The translation key to look up
    ///   - arguments: Variable arguments to substitute into the translated string (supports format specifiers like %@, %d, etc.)
    ///   - table: The name of the strings table to search (optional, defaults to base table)
    ///   - bundle: The bundle containing the strings file (defaults to main bundle)
    ///   - locale: The locale to use for plural rule evaluation and bundle fallback (defaults to current locale)
    /// - Returns: The localized string for the given key with arguments formatted according to the specified locale
    ///
    /// ## Usage
    /// ```swift
    /// let spanishLocale = Locale(identifier: "es_ES")
    ///
    /// // Translation with custom locale
    /// let greeting = tolgee.translate("hello_name", "María", locale: spanishLocale)
    ///
    /// // Plural forms with specific locale
    /// let itemCount = tolgee.translate("item_count", 3, locale: spanishLocale)
    ///
    /// // Useful for testing different localizations
    /// let testLocale = Locale(identifier: "ja_JP")
    /// let japaneseText = tolgee.translate("welcome_message", locale: testLocale)
    /// ```
    ///
    /// - Note: Available on iOS 18.4+ and macOS 15.4+ due to the enhanced bundle localization API
    @available(iOS 18.4, *)
    @available(macOS 15.4, *)
    public func translate(
        _ key: String, _ arguments: CVarArg..., table: String? = nil, bundle: Bundle = .main,
        locale providedLocale: Locale = .current
    )
        -> String
    {
        // Having a custom locale set in Tolgee takes precedence
        let locale = customLocale ?? providedLocale

        let filterRemoteData: Bool
        if customLocale != nil {
            filterRemoteData = false
        } else if providedLocale != .current {
            filterRemoteData = true
        } else {
            filterRemoteData = false
        }

        // First try to get translation from loaded translations
        if let translationEntry = translations[table ?? ""]?[key],
            !filterRemoteData || language == locale.language.languageCode?.identifier
        {
            switch translationEntry {
            case .simple(let string):
                // If we have arguments, try to format the string
                if !arguments.isEmpty {
                    return String(format: string, locale: locale, arguments: arguments)
                }
                return string
            case .plural(let variants):
                let pluralRules = PluralRules(for: locale)
                if let number = arguments.compactMap({ $0 as? NSNumber }).first {
                    switch pluralRules.category(for: number.doubleValue) {
                    case .zero:
                        if let string = variants.zero {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .one:
                        if let string = variants.one {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .two:
                        if let string = variants.two {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .few:
                        if let string = variants.few {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .many:
                        if let string = variants.many {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    case .other:
                        if let string = variants.other {
                            return String(format: string, locale: locale, arguments: arguments)
                        }
                    }
                }
            }
        }

        // Fallback to bundle.localizedString
        let localizedString = bundle.localizedString(
            forKey: key, value: nil, table: table, localizations: [locale.language])

        // If we have arguments, try to format the string
        if !arguments.isEmpty {
            return String(format: localizedString, locale: locale, arguments: arguments)
        }

        return localizedString
    }

    /// Clears all cached translations and ETag data.
    ///
    /// This method removes all cached files from the local cache,
    /// forcing fresh downloads on the next `remoteFetch()` call.
    ///
    /// - Throws: An error if the cache clearing operation fails.
    public func clearCaches() throws {
        cdnEtags.removeAll()
        try cache.clearAll()
        logger.debug("Successfully cleared all cached translations and ETag data")
    }

    /// Sets a custom locale for translations and formatting.
    ///
    /// This method allows you to override the system locale with a custom locale for
    /// translations, plural rules, and string formatting.
    ///
    /// When the language changes,
    /// you should call ``remoteFetch()`` to fetch translations for the new language.
    ///
    /// - Parameters:
    ///   - locale: The locale to use for translations and formatting. Pass `Locale.current`
    ///     to reset to the system locale.
    ///   - language: Optional language code on the Tolgee CDN (e.g., "en", "es", "cs"). If `nil`, the language
    ///     is extracted from the locale. Use this to override the locale's language when it differs from the CDN language code.
    ///
    /// - Note: The SDK must be initialized before calling this method. If the locale
    ///   is already set to the requested value, no action is taken.
    ///
    /// - Important: When the language changes, call ``remoteFetch()`` to fetch
    ///   translations for the new language from the CDN.
    public func setCustomLocale(_ locale: Locale, language: String? = nil) {
        guard isInitialized else {
            logger.error("Tolgee must be initialized before setting a custom locale")
            return
        }

        guard let newLanguage = language ?? locale.language.languageCode?.identifier else {
            logger.error(
                "Failed to determine language identifier from locale: \(locale.identifier)")
            return
        }

        let needsLanguageChange = newLanguage != self.language
        let didUpdateLocale = locale != self.customLocale

        self.language = newLanguage

        if locale == .current {
            self.customLocale = nil
        } else {
            self.customLocale = locale
        }

        if needsLanguageChange {

            translations.removeAll()
            cdnEtags.removeAll()
            loadMemoryCache()

            onTranslationsUpdatedSubscribers.forEach {
                $0.yield(())
            }
        } else if didUpdateLocale {
            onTranslationsUpdatedSubscribers.forEach {
                $0.yield(())
            }
        } else {
            logger.debug("Custom locale is already set to \(locale.identifier), no changes made")
            return
        }

        logger.debug("Set custom locale to \(locale.identifier)")
    }

    private func loadMemoryCache() {

        guard let language else {
            logger.error("Language must be specified to load memory cache")
            return
        }

        guard let cdn = cdnURL else {
            logger.error("CDN URL must be specified to load memory cache")
            return
        }

        // Clear old cache files for base namespace
        cache.clearOldCache(
            descriptor: CacheDescriptor(
                language: language, appVersionSignature: appVersionSignature,
                cdn: cdn.absoluteString))

        // Clear old cache files for all namespaces
        for namespace in namespaces {
            cache.clearOldCache(
                descriptor: CacheDescriptor(
                    language: language, namespace: namespace,
                    appVersionSignature: appVersionSignature, cdn: cdn.absoluteString))
        }

        if let etag = cache.loadCdnEtag(for: .init(language: language, cdn: cdn.absoluteString)) {
            cdnEtags[""] = etag
            logger.debug(
                "Loaded CDN ETag for language: \(language) and base namespace - ETag: \(etag)")
        } else {
            logger.debug("No CDN ETag found for language: \(language) and base namespace")
        }

        if let data = cache.loadRecords(
            for: CacheDescriptor(
                language: language, appVersionSignature: appVersionSignature,
                cdn: cdn.absoluteString))
        {
            do {
                // Load cached translations
                let translations = try JSONParser.loadTranslations(from: data)
                self.translations[""] = translations
                logger.debug(
                    "Loaded cached translations for language: \(language) and base namespace"
                )
            } catch {
                logger.error("Failed to load cached translations: \(error)")
            }
        } else {
            logger.debug("No cached translations found for language: \(language)")
        }

        for namespace in namespaces {

            if let etag = cache.loadCdnEtag(
                for: .init(language: language, namespace: namespace, cdn: cdn.absoluteString))
            {
                cdnEtags[namespace] = etag
                logger.debug(
                    "Loaded CDN ETag for language: \(language), namespace: \(namespace) - ETag: \(etag)"
                )
            } else {
                logger.debug("No CDN ETag found for language: \(language), namespace: \(namespace)")
            }

            if let data = cache.loadRecords(
                for: CacheDescriptor(
                    language: language, namespace: namespace,
                    appVersionSignature: appVersionSignature, cdn: cdn.absoluteString))
            {
                do {
                    // Load cached translations for each namespace
                    let translations = try JSONParser.loadTranslations(from: data)
                    self.translations[namespace] = translations
                    logger.debug(
                        "Loaded cached translations for language: \(language), namespace: \(namespace)"
                    )
                } catch {
                    logger.error(
                        "Failed to load cached translations for namespace '\(namespace)': \(error)")
                }
            } else {
                logger.debug(
                    "No cached translations found for language: \(language), namespace: \(namespace)"
                )
            }
        }
    }
}
