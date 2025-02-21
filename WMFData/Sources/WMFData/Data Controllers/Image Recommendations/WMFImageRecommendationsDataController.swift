import Foundation
import UIKit

public class WMFImageRecommendationsDataController {

	// MARK: - Nested Types

	struct OnboardingStatus: Codable {
		var hasPresentedOnboardingModal: Bool
        var hasPresentedOnboardingTooltips: Bool

		static var `default`: OnboardingStatus {
            return OnboardingStatus(hasPresentedOnboardingModal: false, hasPresentedOnboardingTooltips: false)
		}
	}

	// MARK: - Properties

	private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private let service = WMFDataEnvironment.current.mediaWikiService

	// MARK: - Lifecycle

	public init() {

	}

	// MARK: - Onboarding

	private var onboardingStatus: OnboardingStatus {
		return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.imageRecommendationsOnboarding.rawValue)) ?? OnboardingStatus.default
	}

	public var hasPresentedOnboardingModal: Bool {
		get {
			return onboardingStatus.hasPresentedOnboardingModal
		} set {
			var currentOnboardingStatus = onboardingStatus
			currentOnboardingStatus.hasPresentedOnboardingModal = newValue
			try? userDefaultsStore?.save(key: WMFUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
		}
	}
    
    public var hasPresentedOnboardingTooltips: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingTooltips
        } set {
            var currentOnboardingStatus = onboardingStatus
            currentOnboardingStatus.hasPresentedOnboardingTooltips = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
        }
    }
    
    // MARK: - PUT Send Feedback
    
    public func sendFeedback(project: WMFProject, pageTitle: String, editRevId: UInt64?, fileName: String, accepted: Bool, reasons: [String] = [], caption: String?, completion: @escaping (Result<Void, Error>) -> Void) {

        guard let service else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
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
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WMFMediaWikiServiceRequest(url: url, method: .PUT, backend: .mediaWikiREST, tokenType: .csrf, parameters: parameters as [String : Any])
        
        let completion: (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
        
        service.perform(request: request, completion: completion)
    }
}
