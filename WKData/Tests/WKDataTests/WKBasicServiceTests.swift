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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, parameters: ["one": "1", "two": "2"], acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }

        service.perform(request: request, completion: completion)
    }
    
    func testServerErrorDecodableGet() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
        
        service.perform(request: request, completion: completion)
    }
    
    func testNoInternetConnectionErrorDecodableGet() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
        
        service.perform(request: request, completion: completion)
    }
    
    func testMissingDataDecodableGet() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .GET, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: nil, method: .GET, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidRequest)
            }
        }

        service.perform(request: request, completion: completion)
    }
    
    // MARK: - POST Tests
    
    func testSuccessfulDictionaryPost() {
        
        let service = WKBasicService(urlSession: mockSuccessSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, parameters: ["one": "1", "two": "2"], acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidHttpResponse(500))
            }
        }

        service.perform(request: request, completion: completion)
    }
    
    func testServerErrorDecodablePost() {
        
        let service = WKBasicService(urlSession: mockServerErrorSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                let expectedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
        
        service.perform(request: request, completion: completion)
    }
    
    func testNoInternetConnectionErrorDecodablePost() {
        
        let service = WKBasicService(urlSession: mockNoInternetConnectionSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon no internet connection")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, .missingData)
            }
        }
        
        service.perform(request: request, completion: completion)
    }
    
    func testMissingDataDecodablePost() {
        
        let service = WKBasicService(urlSession: mockMissingDataSession)
        let request = WKBasicServiceRequest(url: URL(string: "http://wikipedia.org")!, method: .POST, acceptType: .json)

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
        let request = WKBasicServiceRequest(url: nil, method: .POST, acceptType: .json)
        
        let completion: (Result<Data, Error>) -> Void = { result in
            switch result {
            case .success:
                XCTFail("Unexpected success upon server error")
            case .failure(let error):
                XCTAssertEqual(error as? WKServiceError, WKServiceError.invalidRequest)
            }
        }

        service.perform(request: request, completion: completion)
    }
}
