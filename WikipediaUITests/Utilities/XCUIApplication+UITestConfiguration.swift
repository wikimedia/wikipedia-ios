import Foundation
import XCTest

extension XCUIApplication {
    func configureForUITestLaunch(configuration: UITestConfiguration = UITestConfiguration()) {
        addLaunchArguments(configuration.launchArguments)
    }

    private func addLaunchArguments(_ argumentValues: [UITestLaunchArgumentValue]) {
        for argumentValue in argumentValues {
            // Key
            launchArguments.append(argumentValue.key.rawValue)
            // Value
            launchArguments.append(argumentValue.value)
        }
    }
}
