import XCTest
@testable import Wikipedia

class MeasurableArticleViewController: ArticleViewController {
    
    var initialLoadCompletion: (() -> Void)?
    
    override func handlePCSDidFinishFinalSetup() {
        super.handlePCSDidFinishFinalSetup()
        initialLoadCompletion?()
    }
}

class MeasurableArticlePeekPreviewViewController: ArticlePeekPreviewViewController {
    var displayCompletion: (() -> Void)?
    
    override func updatePreferredContentSize(for contentWidth: CGFloat) {
        super.updatePreferredContentSize(for: contentWidth)
        displayCompletion?()
    }
}

class ArticlePerformanceTests: XCTestCase {
    
    private var articleURL: URL! = URL(string: "https://en.wikipedia.org/wiki/Dog")
    private var appSchemeArticleURL: URL! = URL(string: "app://en.wikipedia.org/wiki/Dog")
    
    override func setUp() {
        super.setUp()
        
        LSNocilla.sharedInstance().start()
        setupNetworkStubs()
    }

    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }

    private func setupNetworkStubs() {
        
        guard let dogSummaryJSONData = wmf_bundle().wmf_data(fromContentsOfFile: "DogArticleSummary", ofType: "json"),
            let dogCollageImageData = wmf_bundle().wmf_data(fromContentsOfFile:"CollageOfNineDogs", ofType:"jpg"),
            let userGroupsData = wmf_bundle().wmf_data(fromContentsOfFile:"UserInfoGroups", ofType:"json"),
            let mobileHTMLData = wmf_bundle().wmf_data(fromContentsOfFile:"DogMobileHTML", ofType:"html"),
            let mobileBaseCSSData = wmf_bundle().wmf_data(fromContentsOfFile:"MobileBase", ofType:"css"),
            let mobileSiteCSSData = wmf_bundle().wmf_data(fromContentsOfFile:"MobileSite", ofType:"css"),
            let mobilePCSCSSData = wmf_bundle().wmf_data(fromContentsOfFile:"MobilePCS", ofType:"css"),
            let mobilePCSJSData = wmf_bundle().wmf_data(fromContentsOfFile:"MobilePCS", ofType:"js"),
            let i18PCSData = wmf_bundle().wmf_data(fromContentsOfFile:"PCSI18N", ofType: "json"),
            let redPencilImageData = wmf_bundle().wmf_data(fromContentsOfFile:"RedPencilIcon", ofType:"png"),
            let commonsLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"59pxCommonsLogo.svg", ofType:"webp"),
            let footerDog1ImageData = wmf_bundle().wmf_data(fromContentsOfFile:"64pxAussieBlacktri", ofType:"jpg"),
            let footerDog2ImageData = wmf_bundle().wmf_data(fromContentsOfFile:"64pxOkapi2", ofType:"jpg"),
            let wiktionaryLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"54pxWiktionaryLogoV2.svg", ofType:"webp"),
            let smallCommonsLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"40pxCommonsLogo.svg", ofType:"webp"),
            let wikiQuoteLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"46pxWikiquoteLogo.svg", ofType:"webp"),
            let wikiSpeciesLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"46pxWikispeciesLogo.svg", ofType:"webp"),
            let wikiSourceLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"51pxWikisourceLogo.svg", ofType:"webp"),
            let wikiBooksLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"54pxWikibooksLogo.svg", ofType:"webp"),
            let wikiNewsLogoImageData = wmf_bundle().wmf_data(fromContentsOfFile:"54pxWikinewsLogo.svg", ofType:"webp"),
            let genericDogImageData = wmf_bundle().wmf_data(fromContentsOfFile:"640pxDogMorphologicalVariation", ofType:"png"),
            let imageRegex = try? NSRegularExpression(pattern: "https://upload.wikimedia.org/wikipedia/commons/thumb.*", options: []) else {
            assertionFailure("Error setting up fixtures.")
            return
        }

        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/summary/Dog" as NSString)
            .andReturn(200)?
            .withHeaders(["Content-Type": "application/json"])?
            .withBody(dogSummaryJSONData as NSData)
        

        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Collage_of_Nine_Dogs.jpg/1280px-Collage_of_Nine_Dogs.jpg" as NSString)
            .andReturnRawResponse(dogCollageImageData)
        
        let _ = stubRequest("POST", "https://en.wikipedia.org/w/api.php" as NSString)
            .withBody("action=query&format=json&meta=userinfo&uiprop=groups" as NSString)?
            .andReturn(200)?
            .withBody(userGroupsData as NSData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Dog" as NSString)
            .andReturn(200)?
            .withBody(mobileHTMLData as NSData)
        
        let _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/css/mobile/base" as NSString)
            .andReturn(200)?
            .withBody(mobileBaseCSSData as NSData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/css/mobile/site" as NSString)
        .andReturn(200)?
        .withBody(mobileSiteCSSData as NSData)
        
        let _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/css/mobile/pcs" as NSString)
        .andReturn(200)?
        .withBody(mobilePCSCSSData as NSData)
        
        let _ = stubRequest("GET", "https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/pcs" as NSString)
        .andReturn(200)?
        .withBody(mobilePCSJSData as NSData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/7/74/Red_Pencil_Icon.png" as NSString)
        .andReturnRawResponse(redPencilImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/59px-Commons-logo.svg.png" as NSString)
        .andReturnRawResponse(commonsLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Aussie-blacktri.jpg/64px-Aussie-blacktri.jpg" as NSString)
        .andReturnRawResponse(footerDog1ImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Okapi2.jpg/64px-Okapi2.jpg" as NSString)
        .andReturnRawResponse(footerDog2ImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Okapi2.jpg/64px-Okapi2.jpg" as NSString)
        .andReturnRawResponse(footerDog2ImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/0/06/Wiktionary-logo-v2.svg/54px-Wiktionary-logo-v2.svg.png" as NSString)
        .andReturnRawResponse(wiktionaryLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/en/thumb/4/4a/Commons-logo.svg/40px-Commons-logo.svg.png" as NSString)
        .andReturnRawResponse(smallCommonsLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Wikinews-logo.svg/54px-Wikinews-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiNewsLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikiquote-logo.svg/46px-Wikiquote-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiQuoteLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Wikisource-logo.svg/51px-Wikisource-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiSourceLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikibooks-logo.svg/54px-Wikibooks-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiBooksLogoImageData)
        
        let _ = stubRequest("GET", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Wikispecies-logo.svg/46px-Wikispecies-logo.svg.png" as NSString)
        .andReturnRawResponse(wikiSpeciesLogoImageData)
        
        let _ = stubRequest("GET", "https://en.wikipedia.org/api/rest_v1/data/i18n/pcs" as NSString)
        .andReturn(200)?
        .withBody(i18PCSData as NSData)
        
        let _ = stubRequest("GET", imageRegex)
        .andReturnRawResponse(genericDogImageData)
        
    }

    //represents the speed at which article content is seen on screen
    func testArticleSetupTime() {
        
        self.measure {
            
            let dataStore = MWKDataStore.temporary()
            guard let measurableArticleVC = MeasurableArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let setupExpectation = expectation(description: "Waiting for article initial setup call")
            
            measurableArticleVC.initialLoadCompletion = {
                setupExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.keyWindow?.rootViewController = measurableArticleVC
            let _ = measurableArticleVC.view
        
            wait(for: [setupExpectation], timeout: 10)
        }
    }
    
    //represents the speed at which the context menu configuration is generated from a 3D touch on an article link
    func testContextMenuConfigTime() {
        
        let dataStore = MWKDataStore.temporary()
        self.measure {
            
            guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: .light) else {
                XCTFail("Unable to instantiate MeasurableArticleViewController")
                return
            }
            
            let contextExpectation = expectation(description: "Waiting for context menu configuration call")
            
            if #available(iOS 13.0, *) {
                articleVC.contextMenuConfigurationForLinkURL(appSchemeArticleURL) { (completionType, menuConfig) in
                    if completionType == .bail {
                       XCTFail("Menu config should not bail.")
                    }
                    
                    if completionType == .timeout {
                        XCTFail("Menu config should not time out.")
                    }
                    
                    contextExpectation.fulfill()
                    dataStore.clearTemporaryCache()
                }
            } else {
                contextExpectation.fulfill()
            }
        
            wait(for: [contextExpectation], timeout: 1)
        }
    }
    
    func testArticlePeekPreviewControllerDisplayTime() {
        
        let dataStore = MWKDataStore.temporary()
        
        self.measure {
        
            let peekVC = MeasurableArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: .standard)
            
            let displayExpectation = expectation(description: "Waiting for MeasurableArticlePeekPreviewViewController displayCompletion call")
            
            peekVC.displayCompletion = {
                displayExpectation.fulfill()
                UIApplication.shared.keyWindow?.rootViewController = nil
                dataStore.clearTemporaryCache()
            }
            
            UIApplication.shared.keyWindow?.rootViewController = peekVC
            let _ = peekVC.view
            
            wait(for: [displayExpectation], timeout: 10)
        }
    }
}
