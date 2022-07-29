import Foundation
import WMF
import MapKit

extension WikidataFetcher {
    private func wikidata(forArticleURL articleURL: URL, failure: @escaping (Error) -> Void, success: @escaping ([String: Any]) -> Void) {
        guard let title = articleURL.wmf_title,
            let language = articleURL.wmf_languageCode else {
                failure(RequestError.invalidParameters)
                return
        }
        
        let queryParameters = ["action": "wbgetentities", "title": title, "sites": "\(language)wiki", "format": "json"]
        let components = configuration.wikidataAPIURLComponents(with: queryParameters)
        session.getJSONDictionary(from: components.url, ignoreCache: false) { (jsonObject, response, error) in
            guard let jsonObject = jsonObject else {
                failure(RequestError.unexpectedResponse)
                return
            }
            success(jsonObject)
        }
    }
    
    func wikidataBoundingRegion(forArticleURL articleURL: URL, failure: @escaping (Error) -> Void, success: @escaping (MKCoordinateRegion) -> Void) {
        wikidata(forArticleURL: articleURL, failure: failure) { (jsonObject) in
            guard let entities = jsonObject["entities"] as? [String: Any],
                let entity = entities.values.first as? [String: Any],
                let claims = entity["claims"] as? [String: Any] else {
                failure(RequestError.unexpectedResponse)
                return
            }
            
            let keys = ["P1332", "P1333", "P1334", "P1335"] // bounding coordinates

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
                failure(RequestError.unexpectedResponse)
                return
            }

            success(coordinates.wmf_boundingRegion(with: 1))
        }
    }
}
