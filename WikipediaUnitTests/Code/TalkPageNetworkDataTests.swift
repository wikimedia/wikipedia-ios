
import XCTest
@testable import Wikipedia
@testable import WMF

class TalkPageNetworkDataTests: XCTestCase {
    
    let session = Session.shared

    func testLocalJsonDecodesToTalkPage() {
        guard let json = wmf_bundle().wmf_data(fromContentsOfFile: "TalkPage", ofType: "json") else {
            XCTFail("Failure pulling local talk page json")
            return
        }
        do {
            let result: NetworkTalkPage = try session.jsonDecodeData(data: json)
            XCTAssertEqual(result.name, "Pixiu")
            XCTAssertEqual(result.discussions.count, 1, "Unexpected discussion count")
            XCTAssertEqual(result.discussions[0].title, "Would you please help me expand the Puppy cat article?", "Unexpected discussion title")
            XCTAssertEqual(result.discussions[0].items.count, 2, "Unexpected discussion items count")
            let firstItem = result.discussions[0].items[0]
            XCTAssertEqual(firstItem.text, "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last wee. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected discussion item text")
            XCTAssertEqual(firstItem.depth, 0, "Unexpected discussion item depth")
            XCTAssertEqual(firstItem.unalteredText, "<table><tr><td>Insert bonkers template here</td></tr></table> Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last wee. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected discussion item unalteredText")
            
            let secondItem = result.discussions[0].items[1]
            XCTAssertEqual(secondItem.text, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected discussion item text")
            XCTAssertEqual(secondItem.depth, 1, "Unexpected discussion item depth")
            XCTAssertEqual(secondItem.unalteredText, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw. <img src=\'https://upload.wikimedia.org/wikipedia/commons/c/c0/A_cat%27s_paw_2%2C_ubt.JPG\' /> <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected discussion item unalteredText")
            
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    }
}
