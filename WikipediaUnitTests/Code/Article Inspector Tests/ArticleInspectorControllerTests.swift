
import XCTest
@testable import Wikipedia

@available(iOS 13.0, *)
class ArticleInspectorControllerTests: XCTestCase {
    
    var wikiWhoHtml: String!
    var articleHtml: String!

    override func setUpWithError() throws {
        
        guard let wikiWhoHtml = wmf_bundle().wmf_string(fromContentsOfFile: "ArticleInspector-ExtendedHtml", ofType: "html"),
              let articleHtml = wmf_bundle().wmf_string(fromContentsOfFile: "ArticleInspector-Article", ofType: "html") else {
            XCTFail("Failure setting up MockSession for ArticleInspector")
            return
        }
        
        self.wikiWhoHtml = wikiWhoHtml
        self.articleHtml = articleHtml
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseArticleHtmlIntoIndividualSections() throws {
        
        let url = URL(string: "https://en.wikipedia.org")! //this value doesn't matter
        let controller = ArticleInspectorController(articleURL: url)
        
        let individualSections = try controller.testIndividualSectionsFromHtml(articleHtml)
        XCTAssertEqual(individualSections.count, 12)
        let firstSection = individualSections.first!
        XCTAssertEqual(firstSection.paragraphs.count, 4)
        let firstParagraph = firstSection.paragraphs.first!
        XCTAssertEqual(firstParagraph.sentences.count, 2)
        let firstSentence = firstParagraph.sentences.first!
        XCTAssertEqual(firstSentence.htmlText, "<b>Apollo 14</b> was the eighth crewed mission in the United States <a href=\"./Apollo_program\" title=\"Apollo program\">Apollo program</a>, the third to <a href=\"./Moon_landing\" title=\"Moon landing\">land on the Moon</a>, and the first to land in the <a href=\"./Geology_of_the_Moon#Highlands\" title=\"Geology of the Moon\">lunar highlands</a>. ")
        XCTAssertEqual(firstSentence.rawText, "Apollo 14 was the eighth crewed mission in the United States Apollo program, the third to land on the Moon, and the first to land in the lunar highlands. ")
        let secondSentence = firstParagraph.sentences[1]
        XCTAssertEqual(secondSentence.htmlText, "It was the last of the \"<a href=\"./List_of_Apollo_missions#Alphabetical_mission_types\" title=\"List of Apollo missions\">H missions</a>\", landings at specific sites of scientific interest on the Moon for two-day stays with two lunar <a href=\"./Extravehicular_activities\" title=\"Extravehicular activities\" class=\"mw-redirect\">extravehicular activities</a> (EVAs or moonwalks).")
        XCTAssertEqual(secondSentence.rawText, "It was the last of the \"H missions\", landings at specific sites of scientific interest on the Moon for two-day stays with two lunar extravehicular activities (EVAs or moonwalks).")
    }
    
    func testParseWikiWhoHtmlIntoIndividualSections() throws {
        
        let url = URL(string: "https://en.wikipedia.org")! //this value doesn't matter
        let controller = ArticleInspectorController(articleURL: url)
        
        let individualSections = try controller.testIndividualSectionsFromHtml(wikiWhoHtml)
        XCTAssertEqual(individualSections.count, 3)
        let firstSection = individualSections.first!
        XCTAssertEqual(firstSection.paragraphs.count, 4)
        let firstParagraph = firstSection.paragraphs.first!
        XCTAssertEqual(firstParagraph.sentences.count, 2)
        let firstSentence = firstParagraph.sentences.first!
        XCTAssertEqual(firstSentence.htmlText, "<b><span class=\"editor-token token-editor-8551\" id=\"token-1415\">Apollo</span><span class=\"editor-token token-editor-8551\" id=\"token-1416\"> 14</span></b><span class=\"editor-token token-editor-8551\" id=\"token-1420\"> was</span><span class=\"editor-token token-editor-7279\" id=\"token-1421\"> the</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1422\"> eighth</span><span class=\"editor-token token-editor-23031705\" id=\"token-1423\"> crewed</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1424\"> mission</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1425\"> in</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1426\"> the</span><span class=\"editor-token token-editor-67509110f2ed6b4e9fa6ad17fa6f84be\" id=\"token-1427\"> United</span><span class=\"editor-token token-editor-67509110f2ed6b4e9fa6ad17fa6f84be\" id=\"token-1428\"> States</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1429\"> <a href=\"./Apollo_program\" title=\"Apollo program\">Apollo program</a></span><span class=\"editor-token token-editor-8356159\" id=\"token-1433\">,</span><span class=\"editor-token token-editor-7279\" id=\"token-1434\"> the</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1435\"> third</span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1436\"> to</span><span class=\"editor-token token-editor-8356159\" id=\"token-1437\"> <a href=\"./Moon_landing\" title=\"Moon landing\">land on the Moon</a></span><span class=\"editor-token token-editor-35629558\" id=\"token-1446\">,</span><span class=\"editor-token token-editor-35629558\" id=\"token-1447\"> and</span><span class=\"editor-token token-editor-35629558\" id=\"token-1448\"> the</span><span class=\"editor-token token-editor-35629558\" id=\"token-1449\"> first</span><span class=\"editor-token token-editor-35629558\" id=\"token-1450\"> to</span><span class=\"editor-token token-editor-35629558\" id=\"token-1451\"> land</span><span class=\"editor-token token-editor-35629558\" id=\"token-1452\"> in</span><span class=\"editor-token token-editor-35629558\" id=\"token-1453\"> the</span><span class=\"editor-token token-editor-35629558\" id=\"token-1454\"> <a href=\"./Geology_of_the_Moon#Highlands\" title=\"Geology of the Moon\">lunar highlands</a></span><span class=\"editor-token token-editor-0771e4b1834f9b609ed7c31c97ebab15\" id=\"token-1465\">.</span><span class=\"editor-token token-editor-8356159\" id=\"token-1466\"> ")
        XCTAssertEqual(firstSentence.rawText, "Apollo 14 was the eighth crewed mission in the United States Apollo program, the third to land on the Moon, and the first to land in the lunar highlands. ")
        let secondSentence = firstParagraph.sentences[1]
        XCTAssertEqual(secondSentence.htmlText, "It</span><span class=\"editor-token token-editor-8356159\" id=\"token-1467\"> was</span><span class=\"editor-token token-editor-8356159\" id=\"token-1468\"> the</span><span class=\"editor-token token-editor-8356159\" id=\"token-1469\"> last</span><span class=\"editor-token token-editor-8356159\" id=\"token-1470\"> of</span><span class=\"editor-token token-editor-8356159\" id=\"token-1471\"> the</span><span class=\"editor-token token-editor-31685261\" id=\"token-1472\"> \"</span><span class=\"editor-token token-editor-97478\" id=\"token-1473\"><a href=\"./List_of_Apollo_missions#Alphabetical_mission_types\" title=\"List of Apollo missions\">H missions</a></span><span class=\"editor-token token-editor-31685261\" id=\"token-1486\">\"</span><span class=\"editor-token token-editor-8356159\" id=\"token-1487\">,</span><span class=\"editor-token token-editor-8356159\" id=\"token-1488\"> landings</span><span class=\"editor-token token-editor-458237\" id=\"token-1489\"> at</span><span class=\"editor-token token-editor-458237\" id=\"token-1490\"> specific</span><span class=\"editor-token token-editor-458237\" id=\"token-1491\"> sites</span><span class=\"editor-token token-editor-458237\" id=\"token-1492\"> of</span><span class=\"editor-token token-editor-458237\" id=\"token-1493\"> scientific</span><span class=\"editor-token token-editor-458237\" id=\"token-1494\"> interest</span><span class=\"editor-token token-editor-458237\" id=\"token-1495\"> on</span><span class=\"editor-token token-editor-458237\" id=\"token-1496\"> the</span><span class=\"editor-token token-editor-458237\" id=\"token-1497\"> Moon</span><span class=\"editor-token token-editor-458237\" id=\"token-1498\"> for</span><span class=\"editor-token token-editor-97478\" id=\"token-1499\"> two</span><span class=\"editor-token token-editor-275655\" id=\"token-1500\">-</span><span class=\"editor-token token-editor-4861384\" id=\"token-1501\">day</span><span class=\"editor-token token-editor-8356159\" id=\"token-1502\"> stays</span><span class=\"editor-token token-editor-4861384\" id=\"token-1503\"> with</span><span class=\"editor-token token-editor-4861384\" id=\"token-1504\"> two</span><span class=\"editor-token token-editor-4861384\" id=\"token-1505\"> lunar</span><span class=\"editor-token token-editor-4861384\" id=\"token-1506\"> <a href=\"./Extravehicular_activities\" title=\"Extravehicular activities\" class=\"mw-redirect\">extravehicular activities</a></span><span class=\"editor-token token-editor-458237\" id=\"token-1510\"> (</span><span class=\"editor-token token-editor-458237\" id=\"token-1511\">EVAs</span><span class=\"editor-token token-editor-8356159\" id=\"token-1512\"> or</span><span class=\"editor-token token-editor-8356159\" id=\"token-1513\"> moonwalks</span><span class=\"editor-token token-editor-458237\" id=\"token-1514\">)</span><span class=\"editor-token token-editor-8356159\" id=\"token-1515\">.")
        XCTAssertEqual(secondSentence.rawText, "It was the last of the \"H missions\", landings at specific sites of scientific interest on the Moon for two-day stays with two lunar extravehicular activities (EVAs or moonwalks).")
    }
    
    func testParseHtmlIntoCombinedSections() throws {
        let url = URL(string: "https://en.wikipedia.org")! //this value doesn't matter
        let controller = ArticleInspectorController(articleURL: url)
        
        let individualWikiWhoSections = try controller.testIndividualSectionsFromHtml(wikiWhoHtml)
        let individualArticleSections = try controller.testIndividualSectionsFromHtml(articleHtml)
        
        let combinedSections = try controller.testCombinedSections(articleSections: individualArticleSections, wikiWhoSections: individualWikiWhoSections)
    }
}
