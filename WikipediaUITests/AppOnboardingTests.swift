import XCTest
import SnapshotTesting

final class AppOnboardingTests: XCTestCase {
    
    var updateScreenshots: Bool = false

    override func setUpWithError() throws {
        continueAfterFailure = updateScreenshots ? true : false
    }
    
    var screenshotNameSuffix: String {
        // note: not doing theme name here, since onboarding doesn't need to support our themes, only system light/dark mode.
        return "\(deviceLanguageCode)"
    }
    
    override func invokeTest() {
        let shouldRecord: SnapshotTestingConfiguration.Record =
        updateScreenshots ? .all : .missing
        withSnapshotTesting(record: shouldRecord) {
            super.invokeTest()
        }
    }

    func testOnboardingLightMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .light
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 5))

        // Snapshot the introduction screen
        assertSnapshot(of: app.screenshot().image.removingStatusBar(),
                       as: .image(precision: 0.99),
                       named: "introduction-light-\(screenshotNameSuffix)")

        app.buttons["App Onboarding Skip Button"].tap()

        XCTAssertTrue(app.otherElements["Explore View"].waitForExistence(timeout: 5))
    }

    func testOnboardingDarkMode() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.appearance = .dark
        app.launch()

        XCTAssertTrue(app.otherElements["App Onboarding Introduction View"].waitForExistence(timeout: 5))

        assertSnapshot(of: app.screenshot().image.removingStatusBar(),
                       as: .image(precision: 0.99),
                       named: "introduction-dark-\(screenshotNameSuffix)")

        app.buttons["App Onboarding Skip Button"].tap()

        XCTAssertTrue(app.otherElements["Explore View"].waitForExistence(timeout: 5))
    }
}

extension UIImage {
    func removingStatusBar() -> UIImage {
            let statusBarHeight = statusBarHeightForCurrentDevice
            let cropRect = CGRect(x: 0, y: statusBarHeight,
                                  width: size.width,
                                  height: size.height - statusBarHeight)
            let cgImage = cgImage!.cropping(to: cropRect.applying(
                CGAffineTransform(scaleX: scale, y: scale)))!
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        
        private var statusBarHeightForCurrentDevice: CGFloat {
            let screenHeight = UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
            switch screenHeight {
            case 932, 956: return 59  // iPhone 14 Pro Max, 15 Pro Max, 16 Plus etc
            case 852, 874: return 59  // iPhone 14 Pro, 15, 15 Pro, 16
            case 844:      return 47  // iPhone 12, 13, 14
            case 812:      return 44  // iPhone X, XS, 11 Pro
            case 736:      return 20  // iPhone 8 Plus
            case 667:      return 20  // iPhone 8
            default:       return 59  // fallback for unknown devices
            }
        }
}
