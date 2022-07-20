@testable import WMF

import XCTest

class NotificationServiceHelperTest: XCTestCase {
    
    private let testUsername1 = "Test Username"
    private let testUsername2 = "Test Username 2"
    
    var userOneTalkPageNotifications: [RemoteNotificationsAPIController.NotificationsResult.Notification] {
        let dateSevenMinutesAgo = Date(timeInterval: -TimeInterval.sevenMinutes, since: Date())
        let dateEightMinutesAgo = Date(timeInterval: -TimeInterval.eightMinutes, since: Date())
        
        guard let notification1 = standardUserTalkMessageNotification(date: dateEightMinutesAgo),
              let notification2 = standardUserTalkMessageNotification(date: dateSevenMinutesAgo) else {
                  return []
              }
        
        return [notification1, notification2]
    }
    
    var userTwoTalkPageNotifications: [RemoteNotificationsAPIController.NotificationsResult.Notification] {
        let dateSixMinutesAgo = Date(timeInterval: -TimeInterval.sixMinutes, since: Date())
        
        guard let notification = RemoteNotificationsAPIController.NotificationsResult.Notification(project: .wikipedia("en", "English", nil), titleText: testUsername2, titleNamespace: .userTalk, remoteNotificationType: .userTalkPageMessage, date: dateSixMinutesAgo) else {
            return []
        }
        
        return [notification]
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAllNotificationsForSameTalkPage() throws {

        let dateFiveMinutesAgo = Date(timeInterval: -TimeInterval.fiveMinutes, since: Date())
        
        guard let editRevertedNotification = RemoteNotificationsAPIController.NotificationsResult.Notification(project: .wikipedia("en", "English", nil), titleText: "Article", titleNamespace: .main, remoteNotificationType: .editReverted, date: dateFiveMinutesAgo) else {
            XCTFail("Failure setting up test notifications")
                  return
        }
        
        let differentNotifications = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userOneTalkPageNotifications + [editRevertedNotification])
        let talkPageNotificationsDifferentTitles = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userOneTalkPageNotifications + userTwoTalkPageNotifications)
        let talkPageNotificationsSameTitles = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userOneTalkPageNotifications)
        
        XCTAssertTrue(NotificationServiceHelper.allNotificationsAreForSameTalkPage(notifications: talkPageNotificationsSameTitles), "Notifications with a talk title namespace and the same title full text values should be seen as the same.")
        XCTAssertFalse(NotificationServiceHelper.allNotificationsAreForSameTalkPage(notifications: talkPageNotificationsDifferentTitles), "Notifications with a talk title namespace and different  title full text values should not be seen as the same.")
        XCTAssertFalse(NotificationServiceHelper.allNotificationsAreForSameTalkPage(notifications: differentNotifications), "Notifications of different types should not be seen as the same.")
    }
    
    func testTalkPageContent() {
        let singleTalkPageNotification = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userTwoTalkPageNotifications)
        XCTAssertNotNil(NotificationServiceHelper.talkPageContent(for:singleTalkPageNotification), "Talk page content should be returned for a single talk notification.")
        
        let talkPageNotificationsDifferentTitles = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userOneTalkPageNotifications + userTwoTalkPageNotifications)
        XCTAssertNil(NotificationServiceHelper.talkPageContent(for:talkPageNotificationsDifferentTitles), "Bundled talk page content should not be returned for notifications that originated from different talk pages.")
        
        let talkPageNotificationsSameTitles = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>(userOneTalkPageNotifications)
        XCTAssertNotNil(NotificationServiceHelper.talkPageContent(for:talkPageNotificationsSameTitles), "Missing bundled talk page content for notifications that originated from the same talk page.")
    }
    
    func testDetermineNotificationsToDisplayAndCache() {
        // Business logic:
        // Sending in a set of cached notifications (some of which are quite old) along with a set of newly fetched notifications (some of which are also quite old) with some overlap amongst both sets should return only the fetched notifications within the last 10 minutes that are not already in the cached notifications set as notifications to display. The new set of cached notifications returned should be the calculated notifications to display, plus the old cached notifications that aren't older than 1 day
        
        let dateOneYearAgo = Date(timeInterval: -TimeInterval.oneYear, since: Date())
        let dateThirtyDaysAgo = Date(timeInterval: -TimeInterval.thirtyDays, since: Date())
        let dateTwelveHoursAgo = Date(timeInterval: -TimeInterval.twelveHours, since: Date())
        let dateTwoHoursAgo = Date(timeInterval: -TimeInterval.twoHours, since: Date())
        let dateNineMinutesAgo = Date(timeInterval: -TimeInterval.nineMinutes, since: Date())
        let dateSevenMinutesAgo = Date(timeInterval: -TimeInterval.sevenMinutes, since: Date())
        let dateFiveMinutesAgo = Date(timeInterval: -TimeInterval.fiveMinutes, since: Date())
        
        let commonID2hours = "commonNotification2hours"
        let commonID9minutes = "commonNotification9minutes"
        
        // cached notifications has a two older than one day, two within the last day (one overlaps with fetched notifications), three within the last 10 minutes (one overlaps with fetched notifications)
        
        // fetched notifications has a one older than one day, two within the last day (one overlaps with cached notifications), three within the last 10 minutes (one overlaps with cached notifications)
        
        // setup cached notifications
        guard let cachedOneYearAgo = standardUserTalkMessageNotification(customID: "cachedNotification1year", date: dateOneYearAgo),
              let cachedThirtyDaysAgo = standardUserTalkMessageNotification(customID: "cachedNotification30days", date: dateThirtyDaysAgo),
              let cachedTwelveHoursAgo = standardUserTalkMessageNotification(customID: "cachedNotification12hours", date: dateTwelveHoursAgo),
              let cachedTwoHoursAgo = standardUserTalkMessageNotification(customID: commonID2hours, date: dateTwoHoursAgo),
              let cachedNineMinutesAgo = standardUserTalkMessageNotification(customID: commonID9minutes, date: dateNineMinutesAgo),
              let cachedSevenMinutesAgo = standardUserTalkMessageNotification(customID: "cachedNotification7minutes", date: dateSevenMinutesAgo),
              let cachedFiveMinutesAgo = standardUserTalkMessageNotification(customID: "cachedNotification5minutes", date: dateFiveMinutesAgo) else {
                  return
              }
        
        let cachedNotifications = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>([cachedOneYearAgo, cachedThirtyDaysAgo, cachedTwelveHoursAgo, cachedTwoHoursAgo, cachedNineMinutesAgo, cachedSevenMinutesAgo, cachedFiveMinutesAgo])
        
        // setup fetched notifications
        // purposefully not reusing cached notifications - we should test them as separate objects between cached and fetched so that their IDs are compared for identity
        guard let fetchedThirtyDaysAgo = standardUserTalkMessageNotification(customID: "fetchedNotification30days", date: dateThirtyDaysAgo),
              let fetchedTwelveHoursAgo = standardUserTalkMessageNotification(customID: "fetchedNotification12hours", date: dateTwelveHoursAgo),
              let fetchedTwoHoursAgo = standardUserTalkMessageNotification(customID: commonID2hours, date: dateTwoHoursAgo),
              let fetchedNineMinutesAgo = standardUserTalkMessageNotification(customID: commonID9minutes, date: dateNineMinutesAgo),
              let fetchedSevenMinutesAgo = standardUserTalkMessageNotification(customID: "fetchedNotification7minutes", date: dateSevenMinutesAgo),
              let fetchedFiveMinutesAgo = standardUserTalkMessageNotification(customID: "fetchedNotification5minutes", date: dateFiveMinutesAgo) else {
                  return
              }
        
        let fetchedNotifications = Set<RemoteNotificationsAPIController.NotificationsResult.Notification>([fetchedThirtyDaysAgo, fetchedTwelveHoursAgo, fetchedTwoHoursAgo, fetchedNineMinutesAgo, fetchedSevenMinutesAgo, fetchedFiveMinutesAgo])
        
        let result = NotificationServiceHelper.determineNotificationsToDisplayAndCache(fetchedNotifications: fetchedNotifications, cachedNotifications: cachedNotifications)
        let newNotificationsToDisplay = result.notificationsToDisplay
        let newNotificationsToCache = result.notificationsToCache
        
        XCTAssert(newNotificationsToDisplay.count == 2, "Unexpected count of new notifications to display. Should be those from the last 10 minutes that were not already in cachedNotifications input.")
        XCTAssert(newNotificationsToDisplay.contains(fetchedFiveMinutesAgo), "Unexpected items in new notifications to display.")
        XCTAssert(newNotificationsToDisplay.contains(fetchedSevenMinutesAgo), "Unexpected items in new notifications to display.")
        
        XCTAssert(newNotificationsToCache.count == 7, "Unexpected count of new notifications to cache. Should be those within the last 1 day from cached notifications input, plus those from the last 10 minutes from fetched notifications input.")
        
        XCTAssert(newNotificationsToCache.contains(cachedTwelveHoursAgo), "Unexpected items in new notifications to cache.")
        
        // Note these are seen as the same identity, because they were instantiated with the same customID.
        XCTAssert(newNotificationsToCache.contains(cachedTwoHoursAgo), "Unexpected items in new notifications to cache.")
        XCTAssert(newNotificationsToCache.contains(fetchedTwoHoursAgo), "Unexpected items in new notifications to cache.")
        
        // Note these are seen as the same identity, because they were instantiated with the same customID.
        XCTAssert(newNotificationsToCache.contains(cachedNineMinutesAgo), "Unexpected items in new notifications to cache.")
        XCTAssert(newNotificationsToCache.contains(fetchedNineMinutesAgo), "Unexpected items in new notifications to cache.")
        
        XCTAssert(newNotificationsToCache.contains(cachedSevenMinutesAgo), "Unexpected items in new notifications to cache.")
        XCTAssert(newNotificationsToCache.contains(fetchedSevenMinutesAgo), "Unexpected items in new notifications to cache.")
        XCTAssert(newNotificationsToCache.contains(cachedFiveMinutesAgo), "Unexpected items in new notifications to cache.")
        XCTAssert(newNotificationsToCache.contains(fetchedFiveMinutesAgo), "Unexpected items in new notifications to cache.")
    }
    
    func standardUserTalkMessageNotification(customID: String? = nil, date: Date) -> RemoteNotificationsAPIController.NotificationsResult.Notification? {
        return RemoteNotificationsAPIController.NotificationsResult.Notification(project: .wikipedia("en", "English", nil), titleText: testUsername1, titleNamespace: .userTalk, remoteNotificationType: .userTalkPageMessage, date: date, customID: customID)
    }

}

fileprivate extension TimeInterval {
    
    static var oneYear: TimeInterval {
        return TimeInterval(oneDay * 365)
    }
    
    static var fiveMinutes: TimeInterval {
        return TimeInterval(oneMinute * 5)
    }
    
    static var sixMinutes: TimeInterval {
        return TimeInterval(oneMinute * 6)
    }
    
    static var sevenMinutes: TimeInterval {
        return TimeInterval(oneMinute * 7)
    }
    
    static var eightMinutes: TimeInterval {
        return TimeInterval(oneMinute * 8)
    }
    
    static var nineMinutes: TimeInterval {
        return TimeInterval(oneMinute * 9)
    }
    
    static var twelveHours: TimeInterval {
        return TimeInterval(oneHour * 12)
    }
    
    static var twoHours: TimeInterval {
        return TimeInterval(oneHour * 2)
    }
    
    static var thirtyDays: TimeInterval {
        return TimeInterval(oneDay * 30)
    }
}
