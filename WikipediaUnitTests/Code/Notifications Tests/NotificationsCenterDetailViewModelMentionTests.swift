import XCTest
@testable import Wikipedia

class NotificationsCenterDetailViewModelMentionTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        return "notifications-mentions"
    }
    
    func testMentionInUserTalk() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "1")
        
        try testMentionInUserTalkText(detailViewModel: detailViewModel)
        try testMentionInUserTalkImage(detailViewModel: detailViewModel)
        try testMentionInUserTalkActions(detailViewModel: detailViewModel)
    }
    
    func testMentionInUserTalkEditSummary() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "2")
        
        try testMentionInUserTalkEditSummaryText(detailViewModel: detailViewModel)
        try testMentionInUserTalkEditSummaryImage(detailViewModel: detailViewModel)
        try testMentionInUserTalkEditSummaryActions(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalk() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "3")
        
        try testMentionInArticleTalkText(detailViewModel: detailViewModel)
        try testMentionInArticleTalkImage(detailViewModel: detailViewModel)
        try testMentionInArticleTalkActions(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalkEditSummary() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "4")
        
        try testMentionInArticleTalkEditSummaryText(detailViewModel: detailViewModel)
        try testMentionInArticleTalkEditSummaryImage(detailViewModel: detailViewModel)
        try testMentionInArticleTalkEditSummaryActions(detailViewModel: detailViewModel)
    }
    
    func testMentionFailureAnonymous() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "5")
        
        try testMentionFailureAnonymousText(detailViewModel: detailViewModel)
        try testMentionFailureAnonymousActions(detailViewModel: detailViewModel)
    }
    
    func testMentionFailureNotFound() throws {
        
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "6")
        
        try testMentionFailureNotFoundText(detailViewModel: detailViewModel)
        try testMentionFailureNotFoundImage(detailViewModel: detailViewModel)
        try testMentionFailureNotFoundActions(detailViewModel: detailViewModel)
    }
    
    func testMentionSuccess() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "7")
        
        try testMentionSuccessText(detailViewModel: detailViewModel)
        try testMentionSuccessImage(detailViewModel: detailViewModel)
        try testMentionSuccessActions(detailViewModel: detailViewModel)
    }
    
    func testMentionSuccessWikidata() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "8")
        
        try testMentionSuccessWikidataText(detailViewModel: detailViewModel)
        try testMentionSuccessWikidataActions(detailViewModel: detailViewModel)
    }
    
    func testMentionInArticleTalkZhWikiquote() throws {
        let detailViewModel = try detailViewModelFromIdentifier(identifier: "9")
        
        try testMentionInArticleTalkZhWikiquoteText(detailViewModel: detailViewModel)
        try testMentionInArticleTalkZhWikiquoteTextActions(detailViewModel: detailViewModel)
    }
    
    private func testMentionInUserTalkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Reply text mention in talk page User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionInUserTalkImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionInUserTalkActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1033968824&title=User_talk%253AFred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .diff
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Talk page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "In app"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expectedAction2)
    }
    
    private func testMentionInUserTalkEditSummaryText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Mention in edit summary", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Edit Summary Text: User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionInUserTalkEditSummaryImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionInUserTalkEditSummaryActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=1033968849&title=User_talk%253AFred_The_Bird")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Talk page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }
    
    private func testMentionInArticleTalkText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/14/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Jack The Cat Reply text mention in talk page.", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionInArticleTalkActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/wiki/Talk:Blue_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=505586&title=Talk%253ABlue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .diff
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Article"
        let expectedURL2: URL? = URL(string: "https://test.wikipedia.org/wiki/Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "In app"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expectedAction2)
    }
    
    private func testMentionInArticleTalkEditSummaryText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/6/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Mention in edit summary", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Edit Summary Text User:Jack The Cat", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkEditSummaryImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionInArticleTalkEditSummaryActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 2, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Diff"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/w/index.php?oldid=497048&title=Black_Cat")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .diff
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://test.wikipedia.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Article"
        let expectedURL1: URL? = URL(string: "https://test.wikipedia.org/wiki/Black_Cat")!
        let expectedIcon1: NotificationsCenterIconType = .document
        let expectedDestinationText1 = "In app"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
    }
    
    private func testMentionFailureAnonymousText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Failed mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of 47.188.91.144 was not sent because the user is anonymous.", "Invalid contentBody")
    }
    
    private func testMentionFailureAnonymousActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
    }
    
    private func testMentionFailureNotFoundText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Test Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "1/6/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Failed mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Fredirufjdjd was not sent because the user was not found.", "Invalid contentBody")
    }
    
    private func testMentionFailureNotFoundImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionFailureNotFoundActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://test.wikipedia.org/wiki/User_talk:Jack_The_Cat#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
    }
    
    private func testMentionSuccessText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "English Wikipedia", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Successful mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Jack The Cat was sent.", "Invalid contentBody")
    }
    
    private func testMentionSuccessImage(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerImageName, "notifications-type-mention", "Invalid headerImageName")
    }
    
    private func testMentionSuccessActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://en.wikipedia.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
    }
    
    private func testMentionSuccessWikidataText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "Mentions", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Wikidata", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "7/16/21", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Successful mention", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Your mention of Jack The Cat was sent.", "Invalid contentBody")
    }
    
    private func testMentionSuccessWikidataActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 0, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://wikidata.org/wiki/User_talk:Fred_The_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .userTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
    }
    
    private func testMentionInArticleTalkZhWikiquoteText(detailViewModel: NotificationsCenterDetailViewModel) throws {
        XCTAssertEqual(detailViewModel.headerTitle, "From Fred The Bird", "Invalid headerTitle")
        XCTAssertEqual(detailViewModel.headerSubtitle, "Simplified Chinese Wikiquote", "Invalid headerSubtitle")
        XCTAssertEqual(detailViewModel.headerDate, "3/14/22", "Invalid headerDate")
        XCTAssertEqual(detailViewModel.contentTitle, "Section Title", "Invalid contentTitle")
        XCTAssertEqual(detailViewModel.contentBody, "Jack The Cat Reply text mention in talk page.", "Invalid contentBody")
    }
    
    private func testMentionInArticleTalkZhWikiquoteTextActions(detailViewModel: NotificationsCenterDetailViewModel) throws {

        XCTAssertNotNil(detailViewModel.primaryAction, "Invalid primaryAction")
        XCTAssertEqual(detailViewModel.secondaryActions.count, 3, "Invalid secondaryActions count")
        
        let expectedPrimaryText = "Talk page"
        let expectedPrimaryURL: URL? = URL(string: "https://zh.wikiquote.org/wiki/Talk:Blue_Bird#Section_Title")!
        let expectedPrimaryIcon: NotificationsCenterIconType = .document
        let expectedPrimaryDestinationText = "In app"
        let expectedAction: NotificationsCenterActionData.LoggingLabel = .articleTalk
        try testActions(expectedText: expectedPrimaryText, expectedURL: expectedPrimaryURL, expectedIcon: expectedPrimaryIcon, expectedDestinationText: expectedPrimaryDestinationText, actionToTest: detailViewModel.primaryAction!, actionType: expectedAction)
        
        let expectedText0 = "Fred The Bird's user page"
        let expectedURL0: URL? = URL(string: "https://zh.wikiquote.org/wiki/User:Fred_The_Bird")!
        let expectedIcon0: NotificationsCenterIconType = .person
        let expectedDestinationText0 = "On web"
        let expectedAction0: NotificationsCenterActionData.LoggingLabel = .senderPage
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, expectedIcon: expectedIcon0, expectedDestinationText: expectedDestinationText0, actionToTest: detailViewModel.secondaryActions[0], actionType: expectedAction0)
        
        let expectedText1 = "Diff"
        let expectedURL1: URL? = URL(string: "https://zh.wikiquote.org/w/index.php?oldid=505586&title=Talk%253ABlue_Bird")!
        let expectedIcon1: NotificationsCenterIconType = .diff
        let expectedDestinationText1 = "On web"
        let expectedAction1: NotificationsCenterActionData.LoggingLabel = .diff
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, expectedIcon: expectedIcon1, expectedDestinationText: expectedDestinationText1, actionToTest: detailViewModel.secondaryActions[1], actionType: expectedAction1)
        
        let expectedText2 = "Blue Bird"
        let expectedURL2: URL? = URL(string: "https://zh.wikiquote.org/wiki/Blue_Bird")!
        let expectedIcon2: NotificationsCenterIconType = .document
        let expectedDestinationText2 = "On web"
        let expectedAction2: NotificationsCenterActionData.LoggingLabel = .article
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, expectedIcon: expectedIcon2, expectedDestinationText: expectedDestinationText2, actionToTest: detailViewModel.secondaryActions[2], actionType: expectedAction2)
    }
    
}
