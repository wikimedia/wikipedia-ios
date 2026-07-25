import XCTest

/// Replace `FeatureUITests` with the feature or flow under test.
/// Keep this file as a user-journey script; move selectors and waits into robots.
final class FeatureUITests: XCTestCase {

    func testUserCanCompleteFeatureJourney() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            // Continue with intent-level robot calls, for example:
            // .openSearch()
            // .openArticle(named: "Dog")
            // .assertVisible()
    }

    // Add small helpers only when they remove repeated journey setup.
    // Forward file/line so failures point back to the calling test.
    //
    // private func openFeature(file: StaticString = #filePath, line: UInt = #line) -> FeatureRobot {
    //     launchWikipediaAppRobot(onboardingState: .completed)
    //         .explore
    //         .assertVisible(file: file, line: line)
    //         .openFeature(file: file, line: line)
    // }
}
