import Foundation

final class LoadCdnEtagsUseCase: Sendable {
    private let language: String
    private let namespaces: Set<String>
    private let cdnURL: String
    private let appVersionSignature: String?
    private let cache: CacheProtocol

    init(
        language: String,
        namespaces: Set<String>,
        cdnURL: String,
        appVersionSignature: String?,
        cache: CacheProtocol
    ) {
        self.language = language
        self.namespaces = namespaces
        self.cdnURL = cdnURL
        self.appVersionSignature = appVersionSignature
        self.cache = cache
    }

    /// Returns the stored ETags, but only for tables whose translations are cached for the
    /// current app version. An ETag without translations would make the CDN answer
    /// `304 Not Modified` and leave us with nothing to show.
    func callAsFunction() -> [String: String] {
        var etags: [String: String] = [:]

        if hasCachedRecords(namespace: nil),
            let etag = cache.loadCdnEtag(
                for: .init(language: language, cdn: cdnURL))
        {
            etags[""] = etag
        }

        for namespace in namespaces {
            if hasCachedRecords(namespace: namespace),
                let etag = cache.loadCdnEtag(
                    for: .init(
                        language: language, namespace: namespace,
                        cdn: cdnURL))
            {
                etags[namespace] = etag
            }
        }

        return etags
    }

    private func hasCachedRecords(namespace: String?) -> Bool {
        cache.loadRecords(
            for: CacheDescriptor(
                language: language, namespace: namespace,
                appVersionSignature: appVersionSignature, cdn: cdnURL)) != nil
    }
}
