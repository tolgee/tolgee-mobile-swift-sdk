import Foundation
import Testing

@testable import Tolgee

/// A URLSession mock that behaves like a CDN with conditional requests: it returns an ETag on 200,
/// and answers 304 Not Modified (empty body, same ETag) when `If-None-Match` matches.
actor EtagMockURLSession: URLSessionProtocol {
  let body: Data
  let etag: String
  var requests: [URLRequest] = []
  var statusCodes: [Int] = []

  init(body: Data, etag: String) {
    self.body = body
    self.etag = etag
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    requests.append(request)
    let url = request.url!
    if request.value(forHTTPHeaderField: "If-None-Match") == etag {
      statusCodes.append(304)
      let response = HTTPURLResponse(
        url: url, statusCode: 304, httpVersion: nil, headerFields: ["Etag": etag])!
      return (Data(), response)
    }
    statusCodes.append(200)
    let response = HTTPURLResponse(
      url: url, statusCode: 200, httpVersion: nil, headerFields: ["Etag": etag])!
    return (body, response)
  }
}

/// A cache whose `saveRecords` always fails, to simulate a disk write error.
final class FailingSaveCache: CacheProtocol, Sendable {
  struct SaveError: Error {}
  let inner = MockCache()

  func loadRecords(for descriptor: CacheDescriptor) -> Data? { inner.loadRecords(for: descriptor) }
  func saveRecords(_ data: Data, for descriptor: CacheDescriptor) throws { throw SaveError() }
  func clearAll() throws { try inner.clearAll() }
  func loadCdnEtag(for descriptor: CdnEtagDescriptor) -> String? { inner.loadCdnEtag(for: descriptor) }
  func saveCdnEtag(_ descriptor: CdnEtagDescriptor, etag: String) throws {
    try inner.saveCdnEtag(descriptor, etag: etag)
  }
  func clearOldCache(descriptor: CacheDescriptor) { inner.clearOldCache(descriptor: descriptor) }
}

/// Regression tests for https://github.com/tolgee/tolgee-mobile-swift-sdk/issues/15:
/// an ETag must never be sent as `If-None-Match` unless the translations it describes are cached,
/// otherwise a `304 Not Modified` leaves the SDK with nothing to show.
@MainActor
struct AppVersionChangeTests {

  let json = Data(#"{ "Hello, world!": "[remote] Hello, world!" }"#.utf8)
  let cdn = URL(string: "https://cdn.example.com")!
  let locale = Locale(identifier: "en_US")
  let etag = "\"338ddf94\""

  var etagDescriptor: CdnEtagDescriptor { CdnEtagDescriptor(language: "en", cdn: cdn.absoluteString) }
  func records(version: String) -> CacheDescriptor {
    CacheDescriptor(language: "en", appVersionSignature: version, cdn: cdn.absoluteString)
  }

  @Test func translationsReloadAfterAppVersionChange() async throws {
    let cache = MockCache()  // shared across "launches", like the on-disk cache
    let session = EtagMockURLSession(body: json, etag: etag)

    // Launch 1: app version 1.0 build 1
    let v1 = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-1",
      bundleForLanguageDetection: .module)
    v1.initialize(cdn: cdn, locale: locale)
    await v1.remoteFetch()
    #expect(v1.translate("Hello, world!", bundle: .module) == "[remote] Hello, world!")
    #expect(await session.statusCodes == [200])
    #expect(cache.contains(records(version: "1.0-1")))
    #expect(cache.containsEtag(for: etagDescriptor))

    // Launch 2: app version 1.0 build 2, nothing changed in Tolgee
    let v2 = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-2",
      bundleForLanguageDetection: .module)
    v2.initialize(cdn: cdn, locale: locale)

    // Old records are deleted on init; the ETag file is kept
    #expect(!cache.contains(records(version: "1.0-1")))
    #expect(!cache.contains(records(version: "1.0-2")))
    #expect(cache.containsEtag(for: etagDescriptor))

    await v2.remoteFetch()

    // With nothing cached there is nothing to revalidate, so the request must not be conditional
    let lastRequest = await session.requests.last
    #expect(lastRequest?.value(forHTTPHeaderField: "If-None-Match") == nil)
    #expect(await session.statusCodes == [200, 200])

    #expect(v2.translate("Hello, world!", bundle: .module) == "[remote] Hello, world!")
    #expect(cache.contains(records(version: "1.0-2")))
  }

  @Test func etagIsStillUsedWhenTranslationsAreCached() async throws {
    let cache = MockCache()
    let session = EtagMockURLSession(body: json, etag: etag)

    let launch1 = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-1",
      bundleForLanguageDetection: .module)
    launch1.initialize(cdn: cdn, locale: locale)
    await launch1.remoteFetch()

    // Same app version: cached translations load, and the ETag revalidation gets a 304
    let launch2 = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-1",
      bundleForLanguageDetection: .module)
    launch2.initialize(cdn: cdn, locale: locale)
    #expect(launch2.translate("Hello, world!", bundle: .module) == "[remote] Hello, world!")
    await launch2.remoteFetch()

    let lastRequest = await session.requests.last
    #expect(lastRequest?.value(forHTTPHeaderField: "If-None-Match") == etag)
    #expect(await session.statusCodes == [200, 304])
    #expect(launch2.translate("Hello, world!", bundle: .module) == "[remote] Hello, world!")
  }

  @Test func etagIsNotPersistedWhenSavingRecordsFails() async throws {
    let cache = FailingSaveCache()
    let session = EtagMockURLSession(body: json, etag: etag)

    let tolgee = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-1",
      bundleForLanguageDetection: .module)
    tolgee.initialize(cdn: cdn, locale: locale)
    await tolgee.remoteFetch()

    // In-memory translations are still applied for this session
    #expect(tolgee.translate("Hello, world!", bundle: .module) == "[remote] Hello, world!")
    // ...but no ETag is left behind for translations that aren't on disk
    #expect(cache.loadCdnEtag(for: etagDescriptor) == nil)
  }

  @Test func prefetchForAnotherLanguageIgnoresEtagWithoutRecords() async throws {
    let cache = MockCache()
    let session = EtagMockURLSession(body: json, etag: etag)

    // Simulate a leftover ETag from a previous app version, with no translations for this version
    cache.preloadEtag(etag, for: etagDescriptor)

    let tolgee = Tolgee(
      urlSession: session, cache: cache, appVersionSignature: "1.0-2",
      bundleForLanguageDetection: .module)
    tolgee.initialize(cdn: cdn, locale: Locale(identifier: "cs_CZ"))

    // Prefetch "en" while the current language is "cs"
    await tolgee.remoteFetch(language: "en")

    let lastRequest = await session.requests.last
    #expect(lastRequest?.url?.lastPathComponent == "en.json")
    #expect(lastRequest?.value(forHTTPHeaderField: "If-None-Match") == nil)
    #expect(cache.contains(records(version: "1.0-2")))
  }
}
