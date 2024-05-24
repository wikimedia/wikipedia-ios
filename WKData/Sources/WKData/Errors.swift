import Foundation

// MARK: Common

public enum WKDataControllerError: LocalizedError {
    case mediaWikiServiceUnavailable
    case basicServiceUnavailable
    case failureCreatingRequestURL
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
    case paymentsWikiResponseError(String?)
}

public enum WKServiceError: Error, Equatable {
    case invalidRequest
    case invalidHttpResponse(Int?)
    case missingData
    case invalidResponseVersion
    case unexpectedResponse
}

public enum WKUserDefaultsStoreError: Error {
    case unexpectedType
    case failureDecodingJSON(Error)
    case failureEncodingJSON(Error)
}

public enum WKDonateDataControllerError: LocalizedError {
    case paymentsWikiResponseError(reason: String?, orderID: String?)
    
    public var errorDescription: String? {
        switch self {
        case .paymentsWikiResponseError(let reason, _):
            return reason
        }
    }
}
