@testable import WMF
@testable import Wikipedia

import XCTest

class NotificationsCenterViewModelTests: XCTestCase {

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
        XCTFail("Must override dataFileName.")
        return ""
    }

    private var data: Data!
    private var networkModels: [RemoteNotificationsAPIController.NotificationsResult.Notification]!

    var dataStore: MWKDataStore!

    lazy var languageLinkController = {
        dataStore.languageLinkController
    }()
    lazy var configuration = {
        dataStore.configuration
    }()

    private let modelController: RemoteNotificationsModelController! = try? RemoteNotificationsModelController.temporaryModelController()

    override func setUp(completion: @escaping (Error?) -> Void) {
        
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            
            if let gmtTimeZone = TimeZone(abbreviation: "GMT") {
                NSTimeZone.default = gmtTimeZone
            }
            
            guard self.modelController != nil else {
                completion(TestError.failureSettingUpModelController)
                return
            }

            if let data = self.wmf_bundle().wmf_data(fromContentsOfFile: self.dataFileName, ofType: "json") {
                self.data = data
            } else {
                completion(TestError.failurePullingFixtures)
                return
            }

            let decoder = JSONDecoder()
            let networkResult: RemoteNotificationsAPIController.NotificationsResult

            do {
                networkResult = try decoder.decode(RemoteNotificationsAPIController.NotificationsResult.self, from: self.data)
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

            self.saveNetworkModels(networkModels: networkModels) { result in

                switch result {
                case .success:
                    completion(nil)
                case .failure:
                    completion(TestError.failureSavingNetworkNotificationModelsToDatabase)
                }
            }
        })
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
    
    func detailViewModelFromIdentifier(identifier: String) throws -> NotificationsCenterDetailViewModel {
        
        let notification = try fetchManagedObject(identifier: identifier)
        guard let apiIdentifier = notification.wiki,
              let project = WikimediaProject(notificationsApiIdentifier: apiIdentifier, languageLinkController: languageLinkController) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        let commonViewModel = NotificationsCenterCommonViewModel(configuration: configuration, notification: notification, project: project)
        
        return NotificationsCenterDetailViewModel(commonViewModel: commonViewModel)
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
    
    func testActions(expectedText: String, expectedURL: URL?, expectedIcon: NotificationsCenterIconType?, expectedDestinationText: String?, actionToTest: NotificationsCenterAction, isMarkAsRead: Bool = false, isNotificationSettings: Bool = false, actionType: NotificationsCenterActionData.LoggingLabel?) throws {
        let expectedActionData = NotificationsCenterActionData(text: expectedText, url: expectedURL, iconType: expectedIcon, destinationText: expectedDestinationText, actionType: actionType)
        let expectedAction: NotificationsCenterAction
        if isMarkAsRead {
            expectedAction = NotificationsCenterAction.markAsReadOrUnread(expectedActionData)
        } else if isNotificationSettings {
            expectedAction = NotificationsCenterAction.notificationSubscriptionSettings(expectedActionData)
        } else {
            expectedAction = NotificationsCenterAction.custom(expectedActionData)
        }

        XCTAssertEqual(expectedAction, actionToTest, "Invalid action")
        XCTAssertEqual(expectedActionData.actionType?.stringValue, actionToTest.actionData?.actionType?.stringValue)
    }
}
