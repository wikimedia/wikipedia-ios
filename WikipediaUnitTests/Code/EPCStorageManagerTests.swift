
import XCTest
@testable import WMF

class LegacyService {
    static let shared: EventLoggingService = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        return EventLoggingService(session: Session.shared, permanentStorageURL: randomURL)!
    }()
}

class EPCStorageManagerTests: XCTestCase {
    
    let temporaryStorageManager: EPCStorageManager = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        guard let storageManager = EPCStorageManager(legacyEventLoggingService: LegacyService.shared) else {
            XCTFail("Failure initializing temporaryStorageManager.")
            fatalError()
        }
        
        return storageManager
    }()
    
    let temporaryNonCachingStorageManager: EPCStorageManager = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        guard let storageManager = EPCStorageManager(legacyEventLoggingService: LegacyService.shared) else {
            XCTFail("Failure initializing temporaryStorageManager.")
            fatalError()
        }
        
        return storageManager
    }()
    
    let eventGateURI: URL = URL(string: "https://intake-analytics.wikimedia.org/v1/events")!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInstallIDMatchesLegacyInstallID() {
        
        let installID = temporaryStorageManager.installID
        let legacyInstallID = LegacyService.shared.appInstallID
        
        XCTAssertNotNil(installID)
        XCTAssertNotNil(legacyInstallID)
        XCTAssertEqual(installID, legacyInstallID)
    }

}
