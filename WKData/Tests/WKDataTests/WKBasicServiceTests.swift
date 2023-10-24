import XCTest
@testable import WKData
@testable import WKDataMocks

final class WKBasicServiceTests: XCTestCase {

    let mockSuccessSession = WKMockSuccessURLSession()
    let mockServerErrorSession = WKMockServerErrorSession()
    let mockNoInternetConnectionSession = WKMockNoInternetConnectionSession()
    let mockMissingDataSession = WKMockMissingDataSession()
    
    // MARK: - GET Tests

    func testSuccessfulDictionaryGet() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, parameters: ["one": "1", "two": "2"])

        service.perform(request: request) { result in
            switch result {
            case .success(let dict):
               
                guard let requestedURLString = self.mockSuccessSession.url?.absoluteString,
                      !requestedURLString.isEmpty else {
                    XCTFail("Did not save requestsed URL")
                    return
                }
                
                XCTAssert(requestedURLString.isEqual("http://wikipedia.org?one=1&two=2"))
                
                XCTAssertEqual(dict?["oneInt"] as? Int, 1, "Unexpected deserialized data")
                XCTAssertEqual(dict?["twoString"] as? String, "two", "Unexpected deserialized data")
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
        }
    }
    
    func testSuccessfulDecodableGet() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)

        service.performDecodableGET(request: request) { (result: Result<WKMockData, Error>) in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.oneInt, 1, "Unexpected deserialized data")
                XCTAssertEqual(response.twoString, "two", "Unexpected deserialized data")
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
        }
    }
    
    func testServerErrorDictionaryGet() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)

        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }
    }
    
    func testServerErrorDecodableGet() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)

        service.performDecodableGET(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }
    }

    func testNoInternetConnectionDictionaryGet() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)
        
        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
    }
    
    func testNoInternetConnectionErrorDecodableGet() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)

        service.performDecodableGET(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
    }
    
    func testMissingDataDictionaryGet() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)
        
        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
    }
    
    func testMissingDataDecodableGet() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET)

        service.performDecodableGET(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
    }
    
    func testNilURLErrorGet() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: nil, method: .GET)

        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidRequest)
            }
        }
    }
    
    // MARK: - POST Tests
    
    func testSuccessfulDictionaryPost() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, parameters: ["one": "1", "two": "2"])

        service.perform(request: request) { result in
            switch result {
            case .success(let dict):
               
                guard let requestedURLString = self.mockSuccessSession.url?.absoluteString,
                      !requestedURLString.isEmpty else {
                    XCTFail("Did not save requestsed URL")
                    return
                }
                
                XCTAssert(requestedURLString.isEqual("http://wikipedia.org"))
                
                XCTAssertEqual(dict?["oneInt"] as? Int, 1, "Unexpected deserialized data")
                XCTAssertEqual(dict?["twoString"] as? String, "two", "Unexpected deserialized data")
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
        }
    }
    
    func testSuccessfulDecodablePost() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)

        service.performDecodablePOST(request: request) { (result: Result<WKMockData, Error>) in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.oneInt, 1, "Unexpected deserialized data")
                XCTAssertEqual(response.twoString, "two", "Unexpected deserialized data")
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
        }
    }
    
    func testServerErrorDictionaryPost() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)

        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }
    }
    
    func testServerErrorDecodablePost() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)

        service.performDecodablePOST(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }
    }

    func testNoInternetConnectionDictionaryPost() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)
        
        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
    }
    
    func testNoInternetConnectionErrorDecodablePost() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)

        service.performDecodablePOST(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
    }
    
    func testMissingDataDictionaryPost() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)
        
        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
    }
    
    func testMissingDataDecodablePost() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST)

        service.performDecodablePOST(request: request) { (result: Result<WKPaymentMethods, Error>) in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
    }
    
    func testNilURLErrorPost() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: nil, method: .POST)

        service.perform(request: request) { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidRequest)
            }
        }
    }
}
