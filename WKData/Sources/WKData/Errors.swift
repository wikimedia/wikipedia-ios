import Foundation

// MARK: Common

public enum WKDataControllerError: Error {
    case mediaWikiServiceUnavailable
    case basicServiceUnavailable
    case failureCreatingRequestURL
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
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
