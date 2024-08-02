import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFFundraisingCampaignDataControllerTests: XCTestCase {
    
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
    private let nlProject = WMFProject.wikipedia(WMFLanguage(languageCode: "nl", languageVariantCode: nil))

    private var controller: WMFFundraisingCampaignDataController = WMFFundraisingCampaignDataController.shared
    
    override func setUp() async throws {
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
        WMFDataEnvironment.current.serviceEnvironment = .staging
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        self.controller.reset()
        self.controller.service = WMFDataEnvironment.current.basicService
        self.controller.sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
    }
    
    func validFirstDayDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-10-01T12:00:00Z")
        return date!
    }
    
    func validFirstDayPlus6HoursDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-10-01T18:00:00Z")
        return date!
    }
    
    func validFirstDayPlus30HoursDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-10-02T18:00:00Z")
        return date!
    }
    
    func validLastDayDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-11-13T12:00:00Z")
        return date!
    }
    
    func validLastDayPlus30HoursDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-11-14T18:00:00Z")
        return date!
    }
    
    func invalidDate() -> Date {
        let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
        let date = dateFormatter.date(from: "2023-12-15T12:00:00Z")
        return date!
    }

    func testFetchConfigAndLoadAssetWithValidCountryValidDateValidWiki() {
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validENProject = enProject
        let validNLProject = nlProject
        
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        guard let enWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validENProject, currentDate: validDate),
              let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate) else {
            XCTFail("Missing assets")
            return
        }
        
        XCTAssertEqual(enWikiAsset.id, "NL_2023_11", "Unexpected config id")
        XCTAssertEqual(enWikiAsset.textHtml, "<b>Wikipedia is not for sale.</b><br><i>A personal appeal from Jimmy Wales</i><br><br>Today I humbly ask you to reflect on the number of times you have used the Wikipedia app this year, the value you’ve gotten from it, and whether you’re able to give €2 back. The Wikimedia Foundation relies on readers to support the technology that makes Wikipedia and our other projects possible. Being a nonprofit means there is no danger that someone will buy Wikipedia and turn it into their personal playground. If Wikipedia has given you €2 worth of knowledge this year, please give back. Thank you. — <i>Jimmy Wales, founder, Wikimedia Foundation</i>", "Unexpected EN asset text")
        XCTAssertEqual(enWikiAsset.footerHtml, "By donating, you agree to our <a href='https://foundation.wikimedia.org/wiki/Donor_privacy_policy/en'>donor policy</a>.", "Unexpected EN asset footer")
        XCTAssertEqual(enWikiAsset.actions.count, 3, "Unexpected EN asset actions count")
        
        XCTAssertEqual(enWikiAsset.actions[0].title, "Donate now", "Unexpected EN asset positive action title")
        XCTAssertEqual(enWikiAsset.actions[0].url, URL(string: "https://donate.wikimedia.org/?uselang=en&appeal=JimmyQuote&utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=app_2023_enNL_iOS_control")!, "Unexpected EN asset positive action url")
        XCTAssertEqual(enWikiAsset.actions[1].title, "Maybe later", "Unexpected EN asset negative action title")
        XCTAssertEqual(enWikiAsset.actions[2].title, "I already donated", "Unexpected EN asset negative action title")
        XCTAssertEqual(enWikiAsset.currencyCode, "EUR", "Unexpected EN asset currency code")
        
        XCTAssertEqual(nlWikiAsset.id, "NL_2023_11", "Unexpected config id")
        XCTAssertEqual(nlWikiAsset.textHtml, "<b>Wikipedia is niet te koop.</b><br><i>Een persoonlijke boodschap van Jimmy Wales.</i><br><br>Sta je weleens stil bij de keren dat je de Wikipedia-app hebt gebruikt dit jaar? Als je dat nuttig vond, zou je dan €&nbsp;2 willen geven? De Wikimedia Foundation is afhankelijk van lezers die de technologie willen ondersteunen die Wikipedia en andere projecten mogelijk maakt. Omdat we een non-profitorganisatie zijn, bestaat er geen gevaar dat iemand ineens Wikipedia koopt en ermee aan de haal gaat. Als je vindt dat Wikipedia je dit jaar €&nbsp;2 aan kennis heeft gegeven, overweeg dan een donatie. Alvast bedankt. — <i>Jimmy Wales, oprichter van de Wikimedia Foundation</i>", "Unexpected NL asset text")
        XCTAssertEqual(nlWikiAsset.footerHtml, "Als je doneert, ga je akkoord met ons <a href='https://foundation.wikimedia.org/wiki/Donor_privacy_policy/nl'>privacybeleid voor donateurs</a>.", "Unexpected NL asset footer")
        XCTAssertEqual(nlWikiAsset.actions.count, 3, "Unexpected NL asset actions count")
        
        XCTAssertEqual(nlWikiAsset.actions[0].title, "Doneer nu", "Unexpected NL asset positive action title")
        XCTAssertEqual(nlWikiAsset.actions[0].url, URL(string: "https://donate.wikimedia.org/?uselang=nl&appeal=JimmyQuote&utm_medium=WikipediaApp&utm_campaign=iOS&utm_source=app_2023_nlNL_iOS_control")!, "Unexpected NL asset positive action url")
        XCTAssertEqual(nlWikiAsset.actions[1].title, "Misschien later", "Unexpected NL asset negative action title")
        XCTAssertEqual(nlWikiAsset.actions[2].title, "Ik heb al gedoneerd", "Unexpected NL asset negative action title")
        XCTAssertEqual(nlWikiAsset.currencyCode, "EUR", "Unexpected NL asset currency code")
    }

    func testFetchConfigAndLoadAssetWithInvalidCountryValidDateValidWiki() {
        
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let invalidCountry = "US"
        let validDate = validFirstDayDate()
        let validENProject = enProject
        let validNLProject = nlProject
        
        controller.fetchConfig(countryCode: invalidCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        let enWikiAsset = controller.loadActiveCampaignAsset(countryCode: invalidCountry, wmfProject: validENProject, currentDate: validDate)
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: invalidCountry, wmfProject: validNLProject, currentDate: validDate)
    
        XCTAssertNil(enWikiAsset, "Expected EN Asset to be nil for invalid country")
        XCTAssertNil(nlWikiAsset, "Expected NL Asset to be nil for invalid country")
    }
    
    func testFetchConfigAndLoadAssetWithValidCountryInvalidDateValidWiki() {
        
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let invalidDate = invalidDate()
        let validENProject = enProject
        let validNLProject = nlProject
        
        controller.fetchConfig(countryCode: validCountry, currentDate: invalidDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        let enWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validENProject, currentDate: invalidDate)
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: invalidDate)
    
        XCTAssertNil(enWikiAsset, "Expected EN Asset to be nil for invalid date")
        XCTAssertNil(nlWikiAsset, "Expected NL Asset to be nil for invalid date")
    }
    
    func testFetchConfigAndLoadAssetWithValidCountryValidDateInvalidWiki() {
        
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let invalidESProject = esProject
        
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        let esWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: invalidESProject, currentDate: validDate)
        XCTAssertNil(esWikiAsset, "ES asset should be nil")
    }
    
    func testFetchConfigAndLoadAssetWithNoCacheAndNoInternetConnection() {
        WMFDataEnvironment.current.basicService = WMFMockServiceNoInternetConnection()
        controller.service = WMFDataEnvironment.current.basicService
        
        let expectation = XCTestExpectation(description: "Fetch Campaign Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validNLProject = nlProject
        
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                
                XCTFail("Unexpected success")
                
            case .failure:
                break
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let asset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        
        XCTAssertNil(asset, "Expected Nil Asset")
    }
    
    func testFetchConfigAndLoadAssetWithCacheAndNoInternetConnection() {

        let expectation1 = XCTestExpectation(description: "Fetch Config with Internet Connection")
        let expectation2 = XCTestExpectation(description: "Fetch Config without Internet Connection")

        var connectedAsset: WMFFundraisingCampaignConfig.WMFAsset?
        var notConnectedAsset: WMFFundraisingCampaignConfig.WMFAsset?
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validNLProject = nlProject
        
        // First fetch successfully to populate cache

        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                
                connectedAsset = self.controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: self.nlProject, currentDate: validDate)

                // Drop Internet Connection
                WMFDataEnvironment.current.basicService = WMFMockServiceNoInternetConnection()
                self.controller.service = WMFDataEnvironment.current.basicService

                // Fetch again
                self.controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
                    switch result {
                    case .success:
                        
                        XCTFail("Unexpected disconnected success")
                        
                    case .failure:
                        
                        // Despite failure, we still expect to be able to load configs from cache
                        notConnectedAsset = self.controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
                        
                    }
                    
                    expectation2.fulfill()
                }
            case .failure:
                XCTFail("Unexpected connected failure")
            }
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 10.0)
        wait(for: [expectation2], timeout: 10.0)
        
        XCTAssertNotNil(connectedAsset, "Expected Fundraising Config")
        XCTAssertNotNil(notConnectedAsset, "Expected Fundraising Config")
        XCTAssertEqual(connectedAsset?.id, notConnectedAsset?.id, "Expected asset campaign IDs to be equal")
        XCTAssertEqual(connectedAsset?.textHtml, notConnectedAsset?.textHtml, "Expected asset texts to be equal")
    }
  
    func testLoadHiddenAsset() {
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validNLProject = nlProject
        
        // First fetch asset with valid params
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        // Confirm valid asset loads
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        XCTAssertNotNil(nlWikiAsset, "NL asset should not be nil")
        
        // Mark asset as dissmissed
        controller.markAssetAsPermanentlyHidden(asset: nlWikiAsset!)
        
        // Now try to load again
        let hiddenNLWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        XCTAssertNil(hiddenNLWikiAsset, "Hidden NL asset should be nil")
    }
    
    func testLoadMaybeLaterAssetSixHoursLater() {
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validNLProject = nlProject
        
        // First fetch asset with valid params
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        
        // Confirm valid asset loads
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        XCTAssertNotNil(nlWikiAsset, "NL asset should not be nil")
        
        // Mark asset as maybe later
        controller.markAssetAsMaybeLater(asset: nlWikiAsset!, currentDate: validDate)
        
        // Load Six Hours later
        let nlWikiAssetSixHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validFirstDayPlus6HoursDate())
        
        XCTAssertNil(nlWikiAssetSixHoursLater, "NL asset marked as maybe later, then loaded 6 hours later should be nil")
    }
    
    func testLoadMaybeLaterAssetThirtyHoursLater() {
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validFirstDayDate()
        let validNLProject = nlProject
        
        // First fetch asset with valid params
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        
        // Confirm valid asset loads
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        XCTAssertNotNil(nlWikiAsset, "NL asset should not be nil")
        
        // Mark asset as maybe later
        controller.markAssetAsMaybeLater(asset: nlWikiAsset!, currentDate: validDate)
        
        // Load Thirty Hours later
        let nlWikiAssetThirtyHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validFirstDayPlus30HoursDate())
        
        XCTAssertNotNil(nlWikiAssetThirtyHoursLater, "NL asset marked as maybe later, then loaded 30 hours later should not be nil")
    }
    
    func testLoadMaybeLaterAssetAfterCampaignEnds() {
        let expectation = XCTestExpectation(description: "Fetch Config")
        
        let validCountry = "NL"
        let validDate = validLastDayDate()
        let validNLProject = nlProject
        
        // First fetch asset with valid params
        controller.fetchConfig(countryCode: validCountry, currentDate: validDate) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Failure fetching config: \(error)")
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        
        
        // Confirm valid asset loads
        let nlWikiAsset = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validDate)
        XCTAssertNotNil(nlWikiAsset, "NL asset should not be nil")
        
        // Mark asset as maybe later
        controller.markAssetAsMaybeLater(asset: nlWikiAsset!, currentDate: validDate)
        
        // Load next day after campaign ends
        let nlWikiAssetThirtyHoursLater = controller.loadActiveCampaignAsset(countryCode: validCountry, wmfProject: validNLProject, currentDate: validLastDayPlus30HoursDate())
        
        XCTAssertNil(nlWikiAssetThirtyHoursLater, "NL asset marked as maybe later, then loaded after last day of campaign should be nil")
    }
}
