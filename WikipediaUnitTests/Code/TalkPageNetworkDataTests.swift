
import XCTest
@testable import Wikipedia
@testable import WMF

class TalkPageNetworkDataTests: XCTestCase {
    
    let session = MWKDataStore.temporary().session

    func testLocalJsonDecodesToTalkPage() {
        
        guard let json = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json") else {
            XCTFail("Failure pulling local talk page json")
            return
        }
        
        do {
            let result: NetworkBase = try session.jsonDecodeData(data: json)
            let topics = result.topics
            XCTAssertEqual(topics.count, 6, "Unexpected topic count")
            XCTAssertEqual(topics[1].html, "Let’s talk about talk pages", "Unexpected topic title")
            XCTAssertEqual(topics[1].replies.count, 3, "Unexpected replies count")
            let firstItem = topics[1].replies[0]
            XCTAssertEqual(firstItem.html, "Hello, I am testing a new topic from the <a href='./IOS' title='IOS'>iOS</a> app. It is fun. <a href='./Special:Contributions/47.184.10.84' title='Special:Contributions/47.184.10.84'>47.184.10.84</a> 20:50, 21 June 2019 (UTC)", "Unexpected reply text")
            XCTAssertEqual(firstItem.depth, 0, "Unexpected reply depth")
            
            let secondItem = topics[1].replies[1]
            XCTAssertEqual(secondItem.html, "Hello back! This is a nested reply. <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 20:51, 21 June 2019 (UTC)", "Unexpected reply text")
            XCTAssertEqual(secondItem.depth, 1, "Unexpected reply depth")
            
            let thirdItem = topics[1].replies[2]
            XCTAssertEqual(thirdItem.html, "Yes I see, I am nested as well. <a href='./Special:Contributions/47.184.10.84' title='Special:Contributions/47.184.10.84'>47.184.10.84</a> 20:52, 21 June 2019 (UTC)", "Unexpected reply text")
            XCTAssertEqual(thirdItem.depth, 2, "Unexpected reply depth")
            
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    }
}
