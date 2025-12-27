import Foundation

// MARK: - Pure Swift Actor (Clean Implementation)

public actor WMFTempAccountDataController {
    
    public static let shared = WMFTempAccountDataController()
    
    private let mediaWikiService: WMFService?
    
    private var _primaryWikiHasTempAccountsEnabled: Bool?
    public var primaryWikiHasTempAccountsEnabled: Bool {
        return _primaryWikiHasTempAccountsEnabled ?? false
    }
    
    public var wikisWithTempAccountsEnabled: [String] = []
    
    public init(mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.mediaWikiService = mediaWikiService
    }
    
    public func checkWikiTempAccountAvailability(language: String, isCheckingPrimaryWiki: Bool) async -> Bool {
        if wikisWithTempAccountsEnabled.contains(language) {
            if isCheckingPrimaryWiki {
                _primaryWikiHasTempAccountsEnabled = true
            }
            return true
        }
        
        do {
            let hasTempStatus = try await getTempAccountStatusForWiki(language: language)
            
            if hasTempStatus, !wikisWithTempAccountsEnabled.contains(language) {
                wikisWithTempAccountsEnabled.append(language)
            }
            
            if isCheckingPrimaryWiki {
                _primaryWikiHasTempAccountsEnabled = hasTempStatus
            }
            
            return hasTempStatus
        } catch {
            debugPrint("Error fetching temporary account status: \(error)")
            return false
        }
    }
    
    private func getTempAccountStatusForWiki(language: String) async throws -> Bool {
        let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
        let project = WMFProject.wikipedia(wmfLanguage)
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchWikiTempStatus(project: project) { status in
                continuation.resume(with: status)
            }
        }
    }
    
    private func fetchWikiTempStatus(project: WMFProject, completion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        guard let mediaWikiService else {
            completion(.failure(WMFDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            completion(.failure(WMFDataControllerError.failureCreatingRequestURL))
            return
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "format": "json",
            "meta": "siteinfo",
            "formatversion": "2",
            "siprop": "autocreatetempuser"
        ]
        
        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)
        
        mediaWikiService.performDecodableGET(request: request) { (result: Result<TempStatusResponse, Error>) in
            completion(result.map { $0.query.autocreatetempuser.enabled })
        }
    }
}

// MARK: - Response Types

private struct TempStatusResponse: Codable {
    let batchcomplete: Bool
    let query: TempStatusQuery
}

private struct TempStatusQuery: Codable {
    let autocreatetempuser: AutoCreateTempUser
}

private struct AutoCreateTempUser: Codable {
    let enabled: Bool
}

// MARK: - Objective-C Bridge

@objc public final class WMFTempAccountDataControllerSyncBridge: NSObject, @unchecked Sendable {
    
    @objc public static let shared = WMFTempAccountDataControllerSyncBridge(controller: .shared)
    
    private let controller: WMFTempAccountDataController
    
    public init(controller: WMFTempAccountDataController) {
        self.controller = controller
        super.init()
    }
    
    @objc public var primaryWikiHasTempAccountsEnabled: Bool {
        // Synchronous bridge using semaphore
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        let controller = controller
        
        Task {
            result = await controller.primaryWikiHasTempAccountsEnabled
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    @objc public func checkWikiTempAccountAvailability(language: String, isCheckingPrimaryWiki: Bool) {
        let controller = self.controller
        Task {
            await controller.checkWikiTempAccountAvailability(language: language, isCheckingPrimaryWiki: isCheckingPrimaryWiki)
        }
    }
}
