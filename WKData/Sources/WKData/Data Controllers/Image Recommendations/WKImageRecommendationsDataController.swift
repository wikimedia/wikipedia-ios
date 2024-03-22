import Foundation
import UIKit

public class WKImageRecommendationsDataController {

	// MARK: - Nested Types

	struct OnboardingStatus: Codable {
		var hasPresentedOnboardingModal: Bool

		static var `default`: OnboardingStatus {
			return OnboardingStatus(hasPresentedOnboardingModal: false)
		}
	}

	// MARK: - Properties

	private let userDefaultsStore = WKDataEnvironment.current.userDefaultsStore

	// MARK: - Lifecycle

	public init() {

	}

	// MARK: - Onboarding

	private var onboardingStatus: OnboardingStatus {
		return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.imageRecommendationsOnboarding.rawValue)) ?? OnboardingStatus.default
	}

	public var hasPresentedOnboardingModal: Bool {
		get {
			return onboardingStatus.hasPresentedOnboardingModal
		} set {
			var currentOnboardingStatus = onboardingStatus
			currentOnboardingStatus.hasPresentedOnboardingModal = newValue
			try? userDefaultsStore?.save(key: WKUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
		}
	}

}
