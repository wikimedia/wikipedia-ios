import Foundation
import WKData

fileprivate enum WKMockError: Error {
    case unableToPullData
    case unableToDeserialize
}

fileprivate extension WKData.WKServiceRequest {
    var isDonateConfigGet: Bool {
        switch WKDataEnvironment.current.serviceEnvironment {
        case .production:
            return false
        case .staging:
            guard let url,
                  url.host == "test.wikipedia.org",
                  url.path == "/wiki/MediaWiki:AppsDonationConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
        }
    }
    
    var isPaymentMethodsGet: Bool {
        
        switch WKDataEnvironment.current.serviceEnvironment {
        case .production:
            return false
        case .staging:
            guard let url,
                  url.host == "paymentstest4.wmcloud.org",
                  let action = parameters?["action"] as? String else {
                return false
            }
           
            return method == .GET && action == "getPaymentMethods"
        }
    }
    
    var isSubmitPaymentPost: Bool {
        switch WKDataEnvironment.current.serviceEnvironment {
        case .production:
            return false
        case .staging:
            guard let url,
                  url.host == "paymentstest4.wmcloud.org",
                  let action = parameters?["action"] as? String else {
                return false
            }
           
            return method == .POST && action == "submitPayment"
        }
    }
}

public class WKMockDonateBasicService: WKService {
    
    public init() {
        
    }
    
    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            completion(.failure(WKMockError.unableToDeserialize))
            return
        }
        
        completion(.success(jsonDict))
    }
    
    public func performDecodableGET<R: WKServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WKMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) where R : WKData.WKServiceRequest, T : Decodable {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WKMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    private func jsonData(for request: WKData.WKServiceRequest) -> Data? {
        if request.isDonateConfigGet {
            let resourceName = "donate-get-config"
             
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isPaymentMethodsGet {
            let resourceName = "donate-get-payment-methods"
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isSubmitPaymentPost {
            let resourceName = "donate-post-submit-payment-success"
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        }
        
        return nil
    }
}
