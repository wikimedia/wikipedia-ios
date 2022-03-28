@testable import WMF
@testable import Wikipedia

import XCTest

class NotificationsCenterViewModelTests: XCTestCase {

    typealias NotificationsCenterIconType = NotificationsCenterCellViewModel.IconType
    typealias NotificationsCenterAction = NotificationsCenterCellViewModel.SheetAction
    typealias NotificationsCenterActionData = NotificationsCenterCellViewModel.SheetActionData

    enum TestError: Error {
        case failureSettingUpModelController
        case failurePullingFixtures
        case failureConvertingDataToNotificationsResult
        case failurePullingNetworkNotificationModels
        case failureSavingNetworkNotificationModelsToDatabase
        case failurePullingManagedObjectFromDatabase
        case failureConvertingManagedObjectToViewModel
    }

    var dataFileName: String {
        get {
            XCTFail("Must override dataFileName.")
            return ""
        }
    }

    private var data: Data!
    private var networkModels: [RemoteNotificationsAPIController.NotificationsResult.Notification]!

    let dataStore = MWKDataStore.temporary()

    lazy var languageLinkController = {
        dataStore.languageLinkController
    }()
    lazy var configuration = {
        dataStore.configuration
    }()

    private let modelController: RemoteNotificationsModelController! = try? RemoteNotificationsModelController.temporaryModelController()

    override func setUp(completion: @escaping (Error?) -> Void) {

        if let gmtTimeZone = TimeZone(abbreviation: "GMT") {
            NSTimeZone.default = gmtTimeZone
        }
        
        guard modelController != nil else {
            completion(TestError.failureSettingUpModelController)
            return
        }

        if let data = wmf_bundle().wmf_data(fromContentsOfFile: dataFileName, ofType: "json") {
            self.data = data
        } else {
            completion(TestError.failurePullingFixtures)
            return
        }

        let decoder = JSONDecoder()
        let networkResult: RemoteNotificationsAPIController.NotificationsResult

        do {
            networkResult = try decoder.decode(RemoteNotificationsAPIController.NotificationsResult.self, from: data)
        } catch {
            completion(TestError.failureConvertingDataToNotificationsResult)
            return
        }

        guard let networkModels = networkResult.query?.notifications?.list,
              networkModels.count > 0 else {
            completion(TestError.failurePullingNetworkNotificationModels)
            return
        }

        self.networkModels = networkModels

        saveNetworkModels(networkModels: networkModels) { result in

            switch result {
            case .success:
                completion(nil)
            case .failure:
                completion(TestError.failureSavingNetworkNotificationModelsToDatabase)
            }
        }
    }
    
    override func tearDown(completion: @escaping (Error?) -> Void) {
        NSTimeZone.resetSystemTimeZone()
        completion(nil)
    }
    
    func fetchManagedObject(identifier: String) throws -> RemoteNotification {

        let predicate = NSPredicate(format: "id == %@", identifier)
        guard let managedObject = try? self.modelController.fetchNotifications(predicate: predicate).first else {
            throw TestError.failurePullingManagedObjectFromDatabase
        }
        return managedObject
    }

    private func saveNetworkModels(networkModels: [RemoteNotificationsAPIController.NotificationsResult.Notification], completion: @escaping (Result<Void, Error>) -> Void) {

        let backgroundContext = modelController!.newBackgroundContext()
        modelController!.createNewNotifications(moc: backgroundContext, notificationsFetchedFromTheServer: Set(networkModels)) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func testActions(expectedText: String, expectedURL: URL?, actionToTest: NotificationsCenterAction, isMarkAsRead: Bool = false, isNotificationSettings: Bool = false) throws {
        let expectedActionData = NotificationsCenterActionData(text: expectedText, url: expectedURL)
        let expectedAction: NotificationsCenterAction
        if isMarkAsRead {
            expectedAction = NotificationsCenterAction.markAsReadOrUnread(expectedActionData)
        } else if isNotificationSettings {
            expectedAction = NotificationsCenterAction.notificationSubscriptionSettings(expectedActionData)
        } else {
            expectedAction = NotificationsCenterAction.custom(expectedActionData)
        }

        XCTAssertEqual(expectedAction, actionToTest, "Invalid action")
    }
}
