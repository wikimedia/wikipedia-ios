import Foundation
import UIKit

public class WKImageRecommendationsDataController {

	// MARK: - Nested Types

	struct OnboardingStatus: Codable {
		var hasPresentedOnboardingModal: Bool
        var hasPresentedOnboardingTooltips: Bool
        var hasPresentedFeatureAnnouncementModal: Bool

		static var `default`: OnboardingStatus {
            return OnboardingStatus(hasPresentedOnboardingModal: false, hasPresentedOnboardingTooltips: false, hasPresentedFeatureAnnouncementModal: false)
		}
	}

	// MARK: - Properties

	private let userDefaultsStore = WKDataEnvironment.current.userDefaultsStore
    private let service = WKDataEnvironment.current.mediaWikiService

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
    
    public var hasPresentedOnboardingTooltips: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingTooltips
        } set {
            var currentOnboardingStatus = onboardingStatus
            currentOnboardingStatus.hasPresentedOnboardingTooltips = newValue
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
        }
    }

    public var hasPresentedFeatureAnnouncementModal: Bool {
        get {
            return onboardingStatus.hasPresentedFeatureAnnouncementModal
        } set {
            var currentOnboardingStatus = onboardingStatus
            currentOnboardingStatus.hasPresentedFeatureAnnouncementModal = newValue
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
        }
    }
    
    // MARK: - PUT Send Feedback
    
    public func sendFeedback(project: WKProject, pageTitle: String, editRevId: UInt64?, fileName: String, accepted: Bool, reasons: [String] = [], caption: String?, completion: @escaping (Result<Void, Error>) -> Void) {

        guard let service else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        var parameters: [String: Any?] = [
            "filename": fileName,
            "accepted": accepted,
            "reasons": reasons,
            "caption": caption ?? fileName,
            "sectionTitle": nil,
            "sectionNumber": nil
        ]
        
        if let editRevId {
            parameters["editRevId"] = editRevId
        }

        guard let url = URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["growthexperiments","v0","suggestions","addimage","feedback", pageTitle.spacesToUnderscores]) else {
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WKMediaWikiServiceRequest(url: url, method: .PUT, backend: .mediaWikiREST, tokenType: .csrf, parameters: parameters as [String : Any])
        
        let completion: (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(WKDataControllerError.serviceError(error)))
            }
        }
        
        service.perform(request: request, completion: completion)
    }

}
