import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFFundraisingCampaignDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
    private let nlProject = WMFProject.wikipedia(WMFLanguage(languageCode: "nl", languageVariantCode: nil))
    private let controller = WMFFundraisingCampaignDataController.shared

    @Test
    func fetchConfigAndLoadAssetWithValidCountryValidDateValidWiki() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            let enWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: enProject, currentDate: validDate))
            let nlWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))

            #expect(enWikiAsset.id == "NL_2023_11")
            #expect(enWikiAsset.textHtml == "<b>Wikipedia is not for sale.</b><br><i>A personal appeal from Jimmy Wales</i><br><br>Today I humbly ask you to reflect on the number of times you have used the Wikipedia app this year, the value you’ve gotten from it, and whether you’re able to give €2 back. The Wikimedia Foundation relies on readers to support the technology that makes Wikipedia and our other projects possible. Being a nonprofit means there is no danger that someone will buy Wikipedia and turn it into their personal playground. If Wikipedia has given you €2 worth of knowledge this year, please give back. Thank you. — <i>Jimmy Wales, founder, Wikimedia Foundation</i>")
            #expect(enWikiAsset.footerHtml == "By donating, you agree to our <a href='https://foundation.wikimedia.org/wiki/Donor_privacy_policy/en'>donor policy</a>.")
            #expect(enWikiAsset.actions.count == 3)
            #expect(enWikiAsset.actions[0].title == "Donate now")
            #expect(enWikiAsset.actions[0].url == URL(string: "https://donate.wikimedia.org/?uselang=en&appeal=JimmyQuote&utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=app_2023_enNL_iOS_control"))
            #expect(enWikiAsset.actions[1].title == "Maybe later")
            #expect(enWikiAsset.actions[2].title == "I already donated")
            #expect(enWikiAsset.currencyCode == "EUR")

            #expect(nlWikiAsset.id == "NL_2023_11")
            #expect(nlWikiAsset.textHtml == "<b>Wikipedia is niet te koop.</b><br><i>Een persoonlijke boodschap van Jimmy Wales.</i><br><br>Sta je weleens stil bij de keren dat je de Wikipedia-app hebt gebruikt dit jaar? Als je dat nuttig vond, zou je dan €&nbsp;2 willen geven? De Wikimedia Foundation is afhankelijk van lezers die de technologie willen ondersteunen die Wikipedia en andere projecten mogelijk maakt. Omdat we een non-profitorganisatie zijn, bestaat er geen gevaar dat iemand ineens Wikipedia koopt en ermee aan de haal gaat. Als je vindt dat Wikipedia je dit jaar €&nbsp;2 aan kennis heeft gegeven, overweeg dan een donatie. Alvast bedankt. — <i>Jimmy Wales, oprichter van de Wikimedia Foundation</i>")
            #expect(nlWikiAsset.footerHtml == "Als je doneert, ga je akkoord met ons <a href='https://foundation.wikimedia.org/wiki/Donor_privacy_policy/nl'>privacybeleid voor donateurs</a>.")
            #expect(nlWikiAsset.actions.count == 3)
            #expect(nlWikiAsset.actions[0].title == "Doneer nu")
            #expect(nlWikiAsset.actions[0].url == URL(string: "https://donate.wikimedia.org/?uselang=nl&appeal=JimmyQuote&utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=app_2023_nlNL_iOS_control"))
            #expect(nlWikiAsset.actions[1].title == "Misschien later")
            #expect(nlWikiAsset.actions[2].title == "Ik heb al gedoneerd")
            #expect(nlWikiAsset.currencyCode == "EUR")
        }
    }

    @Test
    func fetchConfigAndLoadAssetWithInvalidCountryValidDateValidWiki() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let invalidCountry = "US"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: invalidCountry, currentDate: validDate)

            #expect(controller.loadActiveCampaignAsset(countryCode: invalidCountry, wmfProject: enProject, currentDate: validDate) == nil)
            #expect(controller.loadActiveCampaignAsset(countryCode: invalidCountry, wmfProject: nlProject, currentDate: validDate) == nil)
        }
    }

    @Test
    func fetchConfigAndLoadAssetWithValidCountryInvalidDateValidWiki() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let invalidDate = try invalidDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: invalidDate)

            #expect(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: enProject, currentDate: invalidDate) == nil)
            #expect(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: invalidDate) == nil)
        }
    }

    @Test
    func fetchConfigAndLoadAssetWithValidCountryValidDateInvalidWiki() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            #expect(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: esProject, currentDate: validDate) == nil)
        }
    }

    @Test
    func fetchConfigAndLoadAssetWithNoCacheAndNoInternetConnection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            controller.service = WMFMockServiceNoInternetConnection()

            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            let error = try #require(await #expect(throws: NSError.self) {
                try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)
            })
            #expect(error.domain == NSURLErrorDomain)
            #expect(error.code == NSURLErrorNotConnectedToInternet)

            let asset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate)
            #expect(asset == nil)
        }
    }

    @Test
    func fetchConfigAndLoadAssetWithCacheAndNoInternetConnection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)
            let connectedAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))

            controller.service = WMFMockServiceNoInternetConnection()

            let error = try #require(await #expect(throws: NSError.self) {
                try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)
            })
            #expect(error.domain == NSURLErrorDomain)
            #expect(error.code == NSURLErrorNotConnectedToInternet)

            let notConnectedAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))
            #expect(connectedAsset.id == notConnectedAsset.id)
            #expect(connectedAsset.textHtml == notConnectedAsset.textHtml)
        }
    }

    @Test
    func loadHiddenAsset() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            let nlWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))
            controller.markAssetAsPermanentlyHidden(asset: nlWikiAsset)

            let hiddenNLWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate)
            #expect(hiddenNLWikiAsset == nil)
        }
    }

    @Test
    func loadMaybeLaterAssetSixHoursLater() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            let nlWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))
            controller.markAssetAsMaybeLater(asset: nlWikiAsset, currentDate: validDate)

            let nlWikiAssetSixHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: try validFirstDayPlus6HoursDate())
            #expect(nlWikiAssetSixHoursLater == nil)
        }
    }

    @Test
    func loadMaybeLaterAssetThirtyHoursLater() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validFirstDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            let nlWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))
            controller.markAssetAsMaybeLater(asset: nlWikiAsset, currentDate: validDate)

            let nlWikiAssetThirtyHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: try validFirstDayPlus30HoursDate())
            #expect(nlWikiAssetThirtyHoursLater != nil)
        }
    }

    @Test
    func loadMaybeLaterAssetAfterCampaignEnds() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let validCountry = "NL"
            let validDate = try validLastDayDate()

            try await controller.fetchConfig(countryCode: validCountry, currentDate: validDate)

            let nlWikiAsset = try #require(controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: validDate))
            controller.markAssetAsMaybeLater(asset: nlWikiAsset, currentDate: validDate)

            let nlWikiAssetThirtyHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: nlProject, currentDate: try validLastDayPlus30HoursDate())
            #expect(nlWikiAssetThirtyHoursLater == nil)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.basicService = WMFFundraisingCampaignRequestMockService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    private func validFirstDayDate() throws -> Date {
        try date(from: "2023-10-01T12:00:00Z")
    }

    private func validFirstDayPlus6HoursDate() throws -> Date {
        try date(from: "2023-10-01T18:00:00Z")
    }

    private func validFirstDayPlus30HoursDate() throws -> Date {
        try date(from: "2023-10-02T18:00:00Z")
    }

    private func validLastDayDate() throws -> Date {
        try date(from: "2023-11-13T12:00:00Z")
    }

    private func validLastDayPlus30HoursDate() throws -> Date {
        try date(from: "2023-11-14T18:00:00Z")
    }

    private func invalidDate() throws -> Date {
        try date(from: "2023-12-15T12:00:00Z")
    }

    private func date(from string: String) throws -> Date {
        try #require(DateFormatter.mediaWikiAPIDateFormatter.date(from: string))
    }
}

private final class WMFFundraisingCampaignRequestMockService: WMFService {
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        guard isCampaignConfigRequest(request) else {
            completion(.failure(WMFServiceError.unexpectedResponse))
            return
        }

        WMFMockBasicService(jsonResourceName: "fundraising-campaign-get-config").performDecodableGET(request: request, completion: completion)
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func clearCachedData() {}

    private func isCampaignConfigRequest(_ request: WMFServiceRequest) -> Bool {
        request.method == .GET &&
            request.url?.path == "/wiki/MediaWiki:AppsCampaignConfig.json" &&
            ["donate.wikimedia.org", "test.wikipedia.org"].contains(request.url?.host) &&
            request.parameters?["action"] as? String == "raw"
    }
}

private extension WMFFundraisingCampaignDataController {
    func fetchConfig(countryCode: String, currentDate: Date) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fetchConfig(countryCode: countryCode, currentDate: currentDate) { result in
                continuation.resume(with: result)
            }
        }
    }
}
