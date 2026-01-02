import Foundation

final class RemoteFetchUseCase: Sendable {
    private let cdnURL: URL
    private let language: String
    private let namespaces: Set<String>
    private let appVersionSignature: String?
    private let cdnEtags: [String: String]
    private let fetchCdnService: FetchCdnService
    private let cache: CacheProtocol
    private let logger: TolgeeLog

    struct Response: Sendable {
        var translations: [String: [String: TranslationEntry]]
        var cdnEtags: [String: String]
    }

    init(
        cdnURL: URL,
        language: String,
        namespaces: Set<String>,
        appVersionSignature: String?,
        cdnEtags: [String: String],
        fetchCdnService: FetchCdnService,
        cache: CacheProtocol,
        logger: TolgeeLog
    ) {
        self.cdnURL = cdnURL
        self.language = language
        self.namespaces = namespaces
        self.appVersionSignature = appVersionSignature
        self.cdnEtags = cdnEtags
        self.fetchCdnService = fetchCdnService
        self.cache = cache
        self.logger = logger
    }

    func callAsFunction() async throws -> Response {

        var returnResponse = Response(translations: [:], cdnEtags: cdnEtags)

        await logger.debug(
            String(
                "Fetching translations from CDN for language: \(language), namespaces: \(namespaces)"
            ))

        // Construct file paths for all translation files
        var files: [FetchCdnService.CdnFile] = [
            .init(path: "\(language).json", etag: cdnEtags[""])
        ]  // Base language file
        for namespace in namespaces {
            files.append(.init(path: "\(namespace)/\(language).json", etag: cdnEtags[namespace]))  // Namespace files
        }

        let translationData = try await fetchCdnService.fetchFiles(
            from: cdnURL,
            files: files)

        try Task.checkCancellation()

        // Process the fetched translation data
        for (filePath, result) in translationData {

            let data = result.0
            guard let response = result.1 as? HTTPURLResponse else {
                await logger.error(
                    "Invalid response for file path: \(filePath). It's not an HTTP response.")
                continue
            }

            // Determine the table name from the file path
            let table: String
            if filePath == "\(language).json" {
                table = ""  // Base table
            } else {
                // Extract table name from "table/language.json" format
                table = String(filePath.prefix(while: { $0 != "/" }))
            }

            let returnedEtag = response.allHeaderFields["Etag"] as? String

            do {

                if let returnedEtag, returnedEtag.isEmpty == false,
                    returnedEtag == cdnEtags[table]
                {
                    // I don't feel comfortable disabling the default caching and redirect handling of URLSession
                    // so let's just compare the returned Etag with the last known one and return early if they match.
                    await logger.debug(
                        "No changes for table '\(table)' based on ETag, skipping update")
                    continue
                } else if response.statusCode >= 400 {
                    await logger.error(
                        "Failed to fetch translations for table '\(table)': HTTP \(response.statusCode)"
                    )
                    continue
                }

                let translations = try JSONParser.loadTranslations(from: data)

                returnResponse.translations[table] = translations

                // Cache the fetched data
                let descriptor: CacheDescriptor
                if table.isEmpty {
                    descriptor = CacheDescriptor(
                        language: language, appVersionSignature: self.appVersionSignature,
                        cdn: cdnURL.absoluteString)
                } else {
                    descriptor = CacheDescriptor(
                        language: language, namespace: table,
                        appVersionSignature: self.appVersionSignature,
                        cdn: cdnURL.absoluteString)
                }

                do {
                    try self.cache.saveRecords(data, for: descriptor)
                } catch {
                    await self.logger.error("Failed to save translations to cache: \(error)")
                }

                if let etag = response.allHeaderFields["Etag"] as? String {
                    let etagDescriptor: CdnEtagDescriptor
                    if table.isEmpty {
                        etagDescriptor = CdnEtagDescriptor(
                            language: language,
                            cdn: cdnURL.absoluteString)
                    } else {
                        etagDescriptor = CdnEtagDescriptor(
                            language: language, namespace: table,
                            cdn: cdnURL.absoluteString)
                    }
                    try self.cache.saveCdnEtag(etagDescriptor, etag: etag)
                    returnResponse.cdnEtags[table] = etag
                } else {
                    await self.logger.info(
                        "No etag header found for \(cdnURL.appending(component: filePath))")
                }

                await logger.debug(
                    "Cached translations for language: \(language), namespace: \(table.isEmpty ? "base" : table)"
                )
            } catch {
                await logger.error("Error loading translations for table '\(table)': \(error)")
            }
        }

        return returnResponse
    }
}
