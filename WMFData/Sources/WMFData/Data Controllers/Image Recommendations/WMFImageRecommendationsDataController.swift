import Foundation
import UIKit

public actor WMFImageRecommendationsDataController {

    // MARK: - Nested Types

    struct OnboardingStatus: Codable, Sendable {
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
        get async {
            return onboardingStatus.hasPresentedOnboardingModal
        }
    }
    
    public func setHasPresentedOnboardingModal(_ newValue: Bool) async {
        var currentOnboardingStatus = onboardingStatus
        currentOnboardingStatus.hasPresentedOnboardingModal = newValue
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
    }
    
    public var hasPresentedOnboardingTooltips: Bool {
        get async {
            return onboardingStatus.hasPresentedOnboardingTooltips
        }
    }
    
    public func setHasPresentedOnboardingTooltips(_ newValue: Bool) async {
        var currentOnboardingStatus = onboardingStatus
        currentOnboardingStatus.hasPresentedOnboardingTooltips = newValue
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.imageRecommendationsOnboarding.rawValue, value: currentOnboardingStatus)
    }
    
    // MARK: - PUT Send Feedback
    
    public func sendFeedback(project: WMFProject, pageTitle: String, editRevId: UInt64?, fileName: String, accepted: Bool, reasons: [String] = [], caption: String?, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {

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
        
        let completionHandler: @Sendable (Result<[String: Any]?, Error>) -> Void = { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(WMFDataControllerError.serviceError(error)))
            }
        }
        
        service.perform(request: request, completion: completionHandler)
    }
}

// MARK: - Sync Bridge Extension

extension WMFImageRecommendationsDataController {
    
    nonisolated public var hasPresentedOnboardingModalSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.hasPresentedOnboardingModal
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func setHasPresentedOnboardingModalSyncBridge(_ value: Bool) {
        Task {
            await self.setHasPresentedOnboardingModal(value)
        }
    }
    
    nonisolated public var hasPresentedOnboardingTooltipsSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.hasPresentedOnboardingTooltips
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func setHasPresentedOnboardingTooltipsSyncBridge(_ value: Bool) {
        Task {
            await self.setHasPresentedOnboardingTooltips(value)
        }
    }
    
    nonisolated public func sendFeedbackSyncBridge(project: WMFProject, pageTitle: String, editRevId: UInt64?, fileName: String, accepted: Bool, reasons: [String] = [], caption: String?, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        Task {
            await self.sendFeedback(project: project, pageTitle: pageTitle, editRevId: editRevId, fileName: fileName, accepted: accepted, reasons: reasons, caption: caption, completion: completion)
        }
    }
}
