
import XCTest
@testable import Wikipedia
@testable import WMF

class TalkPageNetworkDataTests: XCTestCase {
    
    let session = Session.shared

    func testLocalJsonDecodesToTalkPage() {
        do {
            let result: NetworkBase = try session.jsonDecodeData(data: TalkPageTestHelpers.TalkPageJSONType.original.json)
            let topics = result.topics
            XCTAssertEqual(topics.count, 1, "Unexpected topic count")
            XCTAssertEqual(topics[0].html, "Would you please help me expand the Puppy cat article?", "Unexpected topic title")
            XCTAssertEqual(topics[0].replies.count, 2, "Unexpected replies count")
            let firstItem = topics[0].replies[0]
            XCTAssertEqual(firstItem.html, "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected reply text")
            XCTAssertEqual(firstItem.depth, 0, "Unexpected reply depth")
            
            let secondItem = topics[0].replies[1]
            XCTAssertEqual(secondItem.html, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected reply text")
            XCTAssertEqual(secondItem.depth, 1, "Unexpected reply depth")
            
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    }
}
