import XCTest
@testable import Wikipedia

final class InsertMediaSettingsViewControllerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testENImageInsertWikitextSettingsDefault() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: "Caption Text", alternativeText: "Alt Text", advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: true, imagePosition: .right, imageType: .thumbnail, imageSize: .default))
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[File:Anneblackburne profile.jpg | thumb | right | alt=Alt Text | Caption Text]]", "Invalid image insert wikitext.")
        XCTAssertEqual(info.caption, "Caption Text", "Invalid image insert caption.")
        XCTAssertEqual(info.altText, "Alt Text", "Invalid image insert alt text.")
    }
    
    func testENImageInsertWikitextSettingsNoWrapBasicCustomSizeCaptionAlt() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: "Caption Text", alternativeText: "Alt Text", advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: false, imagePosition: .none, imageType: .basic, imageSize: .custom(width: 100, height: 200)))
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[File:Anneblackburne profile.jpg | 100x200px | none | alt=Alt Text | Caption Text]]", "Invalid image insert wikitext.")
        XCTAssertEqual(info.caption, "Caption Text", "Invalid image insert caption.")
        XCTAssertEqual(info.altText, "Alt Text", "Invalid image insert alt text.")
    }
    
    func testENImageInsertWikitextSettingsNoWrapBasicCustomSize() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: nil, alternativeText: nil, advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: false, imagePosition: .none, imageType: .basic, imageSize: .custom(width: 100, height: 200)))
        let siteURL = URL(string: "https://en.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[File:Anneblackburne profile.jpg | 100x200px | none]]", "Invalid image insert wikitext.")
        XCTAssertNil(info.caption, "Caption should be nil.")
        XCTAssertNil(info.altText, "Alt text should be nil.")
    }
    
    func testDEImageInsertWikitextSettingsDefault() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: "Caption Text", alternativeText: "Alt Text", advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: true, imagePosition: .right, imageType: .thumbnail, imageSize: .default))
        let siteURL = URL(string: "https://de.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[Datei:Anneblackburne profile.jpg | mini | rechts | alternativtext=Alt Text | Caption Text]]", "Invalid image insert wikitext.")
        XCTAssertEqual(info.caption, "Caption Text", "Invalid image insert caption.")
        XCTAssertEqual(info.altText, "Alt Text", "Invalid image insert alt text.")
    }
    
    func testDEImageInsertWikitextSettingsNoWrapBasicCustomSizeCaptionAlt() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: "Caption Text", alternativeText: "Alt Text", advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: false, imagePosition: .none, imageType: .basic, imageSize: .custom(width: 100, height: 200)))
        let siteURL = URL(string: "https://de.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[Datei:Anneblackburne profile.jpg | 100x200px | ohne | alternativtext=Alt Text | Caption Text]]", "Invalid image insert wikitext.")
        XCTAssertEqual(info.caption, "Caption Text", "Invalid image insert caption.")
        XCTAssertEqual(info.altText, "Alt Text", "Invalid image insert alt text.")
    }
    
    func testDEImageInsertWikitextSettingsNoWrapBasicCustomSize() throws {
        let searchResult = InsertMediaSearchResult(fileTitle: "File:Anneblackburne profile.jpg", displayTitle: "Anneblackburne profile.jpg", thumbnailURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Anneblackburne_profile.jpg/120px-Anneblackburne_profile.jpg")!)
        let settings = InsertMediaSettings(caption: nil, alternativeText: nil, advanced: InsertMediaSettingsViewController.Settings.Advanced(wrapTextAroundImage: false, imagePosition: .none, imageType: .basic, imageSize: .custom(width: 100, height: 200)))
        let siteURL = URL(string: "https://de.wikipedia.org")!
        
        let info = InsertMediaSettingsViewController.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        XCTAssertEqual(info.wikitext, "[[Datei:Anneblackburne profile.jpg | 100x200px | ohne]]", "Invalid image insert wikitext.")
        XCTAssertNil(info.caption, "Caption should be nil.")
        XCTAssertNil(info.altText, "Alt text should be nil.")
    }

}
