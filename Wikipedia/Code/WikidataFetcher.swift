import Foundation
import WMF
import MapKit

enum WikidataFetcherError: Error {
    case genericError
}

class WikidataFetcher: NSObject {
    func wikidata(forArticleURL articleURL: URL, failure: @escaping (Error) -> Void, success: @escaping ([String: Any]) -> Void) {
        guard let title = articleURL.wmf_title,
            let language = articleURL.wmf_language else {
                failure(WikidataFetcherError.genericError)
                return
        }
        
        var components = URLComponents()
        components.host = WikidataAPI.host
        components.path = WikidataAPI.path
        components.scheme = WikidataAPI.scheme
        let actionQueryItem = URLQueryItem(name: "action", value: "wbgetentities")
        let titlesQueryItem = URLQueryItem(name: "titles", value: title)
        let sitesQueryItem = URLQueryItem(name: "sites", value: "\(language)wiki")
        let formatQueryItem = URLQueryItem(name: "format", value: "json")
        components.queryItems = [actionQueryItem, titlesQueryItem, sitesQueryItem, formatQueryItem]
        
        guard let requestURL = components.url else {
            failure(WikidataFetcherError.genericError)
            return
        }
    
        Session.urlSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            guard let data = data else {
                failure(error ?? WikidataFetcherError.genericError)
                return
            }
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    failure(WikidataFetcherError.genericError)
                    return
                }
                success(jsonObject)
            } catch let parseError {
                failure(parseError)
            }
        }).resume()
    }
    
    func wikidataBoundingRegion(forArticleURL articleURL: URL, failure: @escaping (Error) -> Void, success: @escaping (MKCoordinateRegion) -> Void) {
        wikidata(forArticleURL: articleURL, failure: failure) { (jsonObject) in
            guard let entities = jsonObject["entities"] as? [String: Any],
                let entity = entities.values.first as? [String: Any],
                let claims = entity["claims"] as? [String: Any] else {
                failure(WikidataFetcherError.genericError)
                return
            }
            
            let keys = ["P1332", "P1333", "P1334", "P1335"] //bounding coordinates

            let coordinates = keys.compactMap({ (key) -> CLLocationCoordinate2D? in
                guard let values = claims[key] as? [Any] else {
                    return nil
                }
                guard let point = values.first as? [String: Any] else {
                    return nil
                }
                guard let mainsnak = point["mainsnak"] as? [String: Any] else {
                    return nil
                }
                guard let datavalue = mainsnak["datavalue"] as? [String: Any] else {
                    return nil
                }
                guard let value = datavalue["value"] as? [String: Any] else {
                    return nil
                }
                guard let latitude = value["latitude"] as? CLLocationDegrees,
                    let longitude = value["longitude"] as? CLLocationDegrees else {
                        return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            })
            
            guard coordinates.count > 3 else {
                failure(WikidataFetcherError.genericError)
                return
            }

            success(coordinates.wmf_boundingRegion(with: 1))
        }
    }
}
