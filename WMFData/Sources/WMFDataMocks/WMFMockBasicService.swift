import Foundation
import WMFData

#if DEBUG

internal enum WMFMockError: Error {
    case unableToPullData
    case unableToDeserialize
}

fileprivate extension WMFData.WMFServiceRequest {
    
    var isFeatureConfigGet: Bool {
        switch WMFDataEnvironment.current.serviceEnvironment {
        case .production:
            guard let url,
                  url.host == "donate.wikimedia.org",
                  url.path == "/wiki/MediaWiki:AppsFeatureConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
        case .staging:
            guard let url,
                  url.host == "test.wikipedia.org",
                  url.path == "/wiki/MediaWiki:AppsFeatureConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
        }
    }
    
    var isDonateConfigGet: Bool {
        switch WMFDataEnvironment.current.serviceEnvironment {
        case .production:
            guard let url,
                  url.host == "donate.wikimedia.org",
                  url.path == "/wiki/MediaWiki:AppsDonationConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
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
        guard let url,
              url.host == "payments.wikimedia.org",
              let action = parameters?["action"] as? String else {
            return false
        }
       
        return method == .GET && action == "getPaymentMethods"
    }
    
    var isSubmitPaymentPost: Bool {
        guard let url,
              url.host == "payments.wikimedia.org",
              let action = parameters?["action"] as? String else {
            return false
        }
       
        return method == .POST && action == "submitPayment"
    }
    
    var isFundraisingCampaignGet: Bool {
        switch WMFDataEnvironment.current.serviceEnvironment {
        case .production:
            guard let url,
                  url.host == "donate.wikimedia.org",
                  url.path == "/wiki/MediaWiki:AppsCampaignConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
        case .staging:
            guard let url,
                  url.host == "test.wikipedia.org",
                  url.path == "/wiki/MediaWiki:AppsCampaignConfig.json",
                  let action = parameters?["action"] as? String else {
                return false
            }
            
            return method == .GET && action == "raw"
        }
    }
    
    var isArticleSummaryGet: Bool {
        guard let url = url,
              url.absoluteString.contains("/page/summary/") else {
            return false
        }
        
        return true
    }
}

public class WMFMockBasicService: WMFService {
    
    public init() {
        
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        completion(.success(jsonData))
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        
        completion(.success(jsonDict))
    }
    
    public func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) where R : WMFData.WMFServiceRequest, T : Decodable {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    private func jsonData(for request: WMFData.WMFServiceRequest) -> Data? {
        if request.isDonateConfigGet {
            let resourceName = "donate-get-config"
             
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isFeatureConfigGet {
            let resourceName = "feature-get-config"
             
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
            let resourceName = "donate-post-submit-payment-success" // "donate-post-submit-payment-error" for error testing
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isFundraisingCampaignGet {
            let resourceName = "fundraising-campaign-get-config"
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isArticleSummaryGet {
            
            let resourceName = "article-summary-get"
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        }
        
        return nil
    }
}

#endif
