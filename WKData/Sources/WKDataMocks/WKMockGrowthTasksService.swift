import Foundation
import WKData

#if DEBUG

fileprivate extension WKData.WKServiceRequest {

    var isGrowthTasksGet: Bool {

        guard let action = parameters?["action"] as? String,
              let formatversion = parameters?["formatversion"] as? String,
              let format = parameters?["format"] as? String,
              let generator = parameters?["generator"] as? String,
              let ggttasktypes = parameters?["ggttasktypes"] as? String,
              let ggtlimit = parameters?["ggtlimit"] as? String else {
            return false
        }

        return method == .GET && action == "query" && formatversion == "2" && format == "json" && generator == "growthtasks" && ggttasktypes == "image-recommendation" && ggtlimit == "10"
    }

    var isImageRecommendationGet: Bool {
        guard let action = parameters?["action"] as? String,
              let formatversion = parameters?["formatversion"] as? String,
              let format = parameters?["format"] as? String,
              let prop = parameters?["prop"] as? String,
              let pageids = parameters?["pageids"] as? String,
              let gisdtasktype = parameters?["gisdtasktype"] as? String else {
            return false
        }

        return method == .GET && action == "query" && formatversion == "2" && format == "json" && prop == "growthimagesuggestiondata" && pageids == "1" && gisdtasktype == "image-recommendation"
    }
    
    var isImageRecommendationCombinedGet: Bool {
        guard let action = parameters?["action"] as? String,
              let formatversion = parameters?["formatversion"] as? String,
              let format = parameters?["format"] as? String,
              let generator = parameters?["generator"] as? String,
              let gsrsearch = parameters?["gsrsearch"] as? String,
              let prop = parameters?["prop"] as? String else {
            return false
        }

        return method == .GET && action == "query" && formatversion == "2" && format == "json" && generator == "search" && gsrsearch == "hasrecommendation:image" && prop == "growthimagesuggestiondata|revisions|pageimages"
    }
}

public final class WKMockGrowthTasksService: WKService {

    public init() {}

    private func jsonData(for request: WKData.WKServiceRequest) -> Data? {

        if request.isGrowthTasksGet {
            let resourceName = "growth-task-get"
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            return jsonData

        } else if request.isImageRecommendationGet {
            let resourceName = "growth-task-image-recs-get"
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            return jsonData
        } else if request.isImageRecommendationCombinedGet {
            let resourceName = "growth-task-image-recs-combined-get"
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            return jsonData
        }
        
        return nil

    }
    
    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        completion(.success(jsonData))
    }

    public func perform<R: WKServiceRequest>(request: R, completion: @escaping (Result<[String : Any]?, Error>) -> Void) {

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
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) {

    }

}

#endif
