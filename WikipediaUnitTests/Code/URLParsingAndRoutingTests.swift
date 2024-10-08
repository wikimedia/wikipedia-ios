import XCTest
@testable import WMF

class URLParsingAndRoutingTests: XCTestCase {
    let configuration = Configuration.current
    let router = Configuration.current.router
    
    func testWikiResourcePath() {
        XCTAssertEqual("/wiki//æ/_raising".wikiResourcePath, "/æ/_raising")
        XCTAssertNil("/w//æ/_raising".wikiResourcePath)
        XCTAssertEqual("/wiki/อักษรละติน".wikiResourcePath, "อักษรละติน")
    }
    
    func testWResourcePath() {
        XCTAssertEqual("/w/index.php?title=/æ/_raising&oldid=905679984".wResourcePath, "index.php?title=/æ/_raising&oldid=905679984")
    }
    
    func testNamespace() {
        XCTAssertEqual("The_Clash:_Westway_to_the_World".namespaceOfWikiResourcePath(with: "en"), .main)
        XCTAssertEqual("The_Clash:_Westway_to_the_World".namespaceAndTitleOfWikiResourcePath(with: "en").title,  "The_Clash:_Westway_to_the_World")
    }
    
    func testMainPage() {
        let enMainPageURL = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")!
        let dest = router.destination(for: enMainPageURL, permanentUsername: nil)
        switch dest {
        case .inAppLink(let linkURL):
            XCTAssertEqual(linkURL, enMainPageURL.canonical)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testSpecialDestinations() {
        let myTalkURL = URL(string: "https://en.wikipedia.org/wiki/Special:MyTalk")!
        let myTalkDest = router.destination(for: myTalkURL, permanentUsername: "Jimbo Wales")
        
        switch myTalkDest {
        case .userTalk:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
        
        let myContributionsURL = URL(string: "https://en.wikipedia.org/wiki/Special:MyContributions")!
        let myContributionsDest = router.destination(for: myContributionsURL, permanentUsername: "Jimbo Wales")
        
        switch myContributionsDest {
        case .inAppLink:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
        
        let userLoginURL1 = URL(string: "https://en.wikipedia.org/wiki/Special:UserLogin")!
        let userLoginDest1 = router.destination(for: userLoginURL1, permanentUsername: nil)
        
        switch userLoginDest1 {
        case .login:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
        
        let userLoginURL2 = URL(string: "https://en.wikipedia.org/w/index.php?title=Special:UserLogin")!
        let userLoginDest2 = router.destination(for: userLoginURL2, permanentUsername: nil)
        
        switch userLoginDest2 {
        case .login:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
        
        let importReadingListsURL = URL(string: "https://en.wikipedia.org/wiki/Special:ReadingLists?limport=eyJsaXN0Ijp7ImVuIjpbMjE4NjksMzI3NDUsNDQ0NjksNDQ0NzQsODI3ODBdfX0=")!
        let importReadingListsDest = router.destination(for: importReadingListsURL, permanentUsername: nil)
        
        switch importReadingListsDest {
        case .readingListsImport:
            XCTAssertTrue(true)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testDiffDestinations() {
        guard var desktopComponents = URLComponents(string: "https://en.wikipedia.org") else {
            XCTAssertTrue(false)
            return
        }
        
        guard var mobileComponents = URLComponents(string: "https://en.m.wikipedia.org") else {
            XCTAssertTrue(false)
            return
        }
        
        // Special page diff path with only "to" revision ID
        
        desktopComponents.path = "/wiki/Special:MobileDiff/24601"
        var dest = router.destination(for: desktopComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, desktopComponents.url!.canonical)
            XCTAssertNil(fromRevID)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        mobileComponents.path = "/wiki/Special:MobileDiff/24601"
        dest = router.destination(for: mobileComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, mobileComponents.url!.canonical)
            XCTAssertNil(fromRevID)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        // Special page diff path with both "from" and "to" revision IDs
        
        desktopComponents.path = "/wiki/Special:MobileDiff/1150823759...1162159587"
        dest = router.destination(for: desktopComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, desktopComponents.url!.canonical)
            XCTAssertEqual(fromRevID, 1150823759)
            XCTAssertEqual(toRevID, 1162159587)
        default:
            XCTAssertTrue(false)
        }
        
        mobileComponents.path = "/wiki/Special:MobileDiff/1150823759...1162159587"
        dest = router.destination(for: mobileComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL,let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, mobileComponents.url!.canonical)
            XCTAssertEqual(fromRevID, 1150823759)
            XCTAssertEqual(toRevID, 1162159587)
        default:
            XCTAssertTrue(false)
        }
        
        // w/index.php-style diff path with only "to" revision ID
        
        desktopComponents.path = "/w/index.php"
        desktopComponents.query = "title=Chernobyl&diff=24601"
        dest = router.destination(for: desktopComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, desktopComponents.url!.canonical)
            XCTAssertNil(fromRevID)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        mobileComponents.path = "/w/index.php"
        mobileComponents.query = "title=Chernobyl&diff=24601"
        dest = router.destination(for: mobileComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, mobileComponents.url!.canonical)
            XCTAssertNil(fromRevID)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        // w/index.php-style diff path with both "from" and "to" revision IDs
        
        desktopComponents.path = "/w/index.php"
        desktopComponents.query = "title=Chernobyl&diff=24601&oldid=24600"
        dest = router.destination(for: desktopComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, desktopComponents.url!.canonical)
            XCTAssertEqual(fromRevID, 24600)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        mobileComponents.path = "/w/index.php"
        mobileComponents.query = "title=Chernobyl&diff=24601&oldid=24600"
        dest = router.destination(for: mobileComponents.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, let fromRevID, let toRevID):
            XCTAssertEqual(linkURL, mobileComponents.url!.canonical)
            XCTAssertEqual(fromRevID, 24600)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testWikiResourcePathActivity() {
        guard var components = URLComponents(string: "//en.wikipedia.org/wiki/User_talk:Pink_Bull") else {
            XCTAssertTrue(false)
            return
        }
        
        var dest = router.destination(for: components.url!, permanentUsername: nil)
        switch dest {
        case .userTalk(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }

        components.path = "/wiki//æ/_raising"
        dest = router.destination(for: components.url!, permanentUsername: nil)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        components.host = "fr.m.wikipedia.org"
        components.path = "/wiki/France"
        dest = router.destination(for: components.url!, permanentUsername: nil)
        switch dest {
        case .article(let linkURL):
            XCTAssertEqual(linkURL, components.url!.canonical)
        default:
            XCTAssertTrue(false)
        }
        
        // Special should work on frwiki because it's a canonical namespace
        components.path = "/wiki/Special:MobileDiff/24601"
        dest = router.destination(for: components.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, _, let toRevID):
            XCTAssertEqual(linkURL, components.url!.canonical)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
        
        components.host = "zh.m.wikipedia.org"
        components.path = "/wiki/特殊:MobileDiff/24601"
        dest = router.destination(for: components.url!, permanentUsername: nil)
        switch dest {
        case .articleDiff(let linkURL, _, let toRevID):
            XCTAssertEqual(linkURL, components.url!.canonical)
            XCTAssertEqual(toRevID, 24601)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testTitlesWithForwardSlashes() {
        var url = URL(string: "https://en.wikipedia.org/wiki/G/O_Media")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("./Gizmodo")?.absoluteString, "https://en.wikipedia.org/wiki/Gizmodo")
        url = URL(string: "https://en.wikipedia.org/wiki//dev/random")!
        XCTAssertEqual(url.resolvingRelativeWikiHref(".//dev/null")?.absoluteString, "https://en.wikipedia.org/wiki//dev/null")
    }
    
    /// Ensure the 'transcoded' path component is inserted after the language path component for audio hosted on Wikipedia
    func testWikipediaCompatibilityAdjustments() {
        let url = URL(string: "https://upload.wikimedia.org/wikipedia/en/3/3f/DeanScream.ogg")!
        let expected = URL(string: "https://upload.wikimedia.org/wikipedia/en/transcoded/3/3f/DeanScream.ogg/DeanScream.ogg.mp3")!
        XCTAssertEqual(url.byMakingAudioFileCompatibilityAdjustments, expected)
    }
    
    /// Ensure the 'transcoded' path component is inserted after the 'commons' path component for audio hosted on Commons
    func testCommonsCompatibilityAdjustments() {
        let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/8/8a/En-Paprika_%28American%29.oga")!
        let expected = URL(string: "https://upload.wikimedia.org/wikipedia/commons/transcoded/8/8a/En-Paprika_(American).oga/En-Paprika_(American).oga.mp3")!
        XCTAssertEqual(url.byMakingAudioFileCompatibilityAdjustments, expected)
    }
    
    /// Ensure non audio and non-upload.wikimedia.org links aren't transcoded and don't break in unexpected ways
    func testInvalidCompatibilityAdjustment() {
        var url = URL(string: "https://upload.wikimedia.org/commons/3/3f/DeanScream.ogv")!
        XCTAssertFalse(url.isWikimediaHostedAudioFileLink)
        url = URL(string: "https://en.wikipedia.org/commons/3/3f/DeanScream.ogg")!
        XCTAssertFalse(url.isWikimediaHostedAudioFileLink)
    }

    func testSpecialCharactersEncodedOnWiki() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("./COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")?.absoluteString, "https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersUnencodedOnWiki() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("./COVID-19-Pandemie_in_Baden-Württemberg")?.absoluteString, "https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersEncodedOnAnotherWiki() {
        let url = URL(string: "https://en.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")?.absoluteString, "https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersUnencodedOnAnotherWiki() {
        let url = URL(string: "https://en.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-Württemberg")?.absoluteString, "https://de.wikipedia.org/wiki/COVID-19-Pandemie_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersEncodedOnCommons() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg")?.absoluteString, "https://commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersUnencodedOnCommons() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-Württemberg")?.absoluteString, "https://commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg")
    }

    func testSpecialCharactersEncodedOffWiki() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//www.p%C3%BCzzledpint.com")?.absoluteString, "https://www.p%C3%BCzzledpint.com")
    }

    func testSpecialCharactersUnencodedOffWiki() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//www.püzzledpint.com")?.absoluteString, "https://www.p%C3%BCzzledpint.com")
    }

    func testQuestionMark() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//www.puzzledpint.com/page?test=yes")?.absoluteString, "https://www.puzzledpint.com/page?test=yes")
    }

    func testSpecialCharactersEncodedWithQuestionMark() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg?uselang=de")?.absoluteString, "https://commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg?uselang=de")
    }

    func testSpecialCharactersUnencodedWithQuestionMark() {
        let url = URL(string: "https://de.wikipedia.org/wiki/Grinnell_College")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-Württemberg?uselang=de")?.absoluteString, "https://commons.wikimedia.org/wiki/Category:COVID-19_pandemic_in_Baden-W%C3%BCrttemberg?uselang=de")
    }
    
    func testQuestionMarkInPath() {
        let url = URL(string: "https://en.wikipedia.org/wiki/Main_Page")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("./Who's_the_Man%3F")?.absoluteString, "https://en.wikipedia.org/wiki/Who's_the_Man%3F")
    }
    
    func testCaret() {
        let url = URL(string: "https://en.wikipedia.org/wiki/Main_Page")!
        XCTAssertEqual(url.resolvingRelativeWikiHref("//commons.wikimedia.org/wiki/File:^8_Schickelgruber._He_was_sick_two_days_last_week_-_NARA_-_535224.jpg")?.absoluteString, "https://commons.wikimedia.org/wiki/File:%5E8_Schickelgruber._He_was_sick_two_days_last_week_-_NARA_-_535224.jpg")
    }
    
    func testLanguageVariantCodeProperty() {
        var url = URL(string: "https://zh.wikipedia.org")!
        XCTAssertNil(url.wmf_languageVariantCode)
        let languageVariantCode = "zh-hant"
        url.wmf_languageVariantCode = languageVariantCode
        XCTAssertEqual(url.wmf_languageVariantCode, languageVariantCode)

        // Assignment of value type URL preserves the language variant code associated object
        // Both are backed by the same copy-on-write NSURL instance
        let url2 = url
        XCTAssertEqual(url2.wmf_languageVariantCode, languageVariantCode)

        // Creating new URL instances based on the original DOES NOT automatically
        // propagate the language variant code associated object
        let url3 = url.appendingPathComponent("test")
        XCTAssertNotEqual(url3.wmf_languageVariantCode, languageVariantCode)
    }
    
    func testContentLanguageCodeProperty() {
        let languageCode = "zh"
        let languageVariantCode = "zh-hans"
        var url = URL(string: "https://\(languageCode).wikipedia.org")!

        // If languageVariantCode is non-nil and non-empty string, wmf_contentLanguageCode returns languageVariantCode
        url.wmf_languageVariantCode = languageVariantCode
        XCTAssertEqual(url.wmf_contentLanguageCode, languageVariantCode)
        
        // If languageVariantCode is nil, contentLanguageCode returns languageCode
        url.wmf_languageVariantCode = nil
        XCTAssertEqual(url.wmf_contentLanguageCode, languageCode)
        
        // If languageVariantCode is an empty string, contentLanguageCode returns languageCode
        url.wmf_languageVariantCode = ""
        XCTAssertEqual(url.wmf_contentLanguageCode, languageCode)
    }
    
    func testLanguageVariantCodePropertyFromURLComponents() {
        let components = URLComponents(string: "https://sr.wikipedia.org")
        let languageVariantCode = "sr-ec"
        XCTAssertNotNil(components)
        if let components = components {
            let url = components.wmf_URLWithLanguageVariantCode(languageVariantCode)
            XCTAssertNotNil(url)
            XCTAssertEqual(url?.wmf_languageVariantCode, languageVariantCode)
        }
    }

}
