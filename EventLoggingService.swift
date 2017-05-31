import Foundation


class EventLoggingService {

    private static let LoggingEndpoint =
        // production
        "https://meta.wikimedia.org/beacon/event"
        // testing
        // "http://deployment.wikimedia.beta.wmflabs.org/beacon/event";
    
    
    private var urlSession: URLSession {
        get {
            return URLSession.shared
        }
    }
    
    private func logEvent(_ event: Dictionary<String, Any>, revision:Int, wiki: String) -> Void {

        let payload: [String:Any] =  [
            "event": event,
            "revision": revision,
            "wiki": wiki
        ]
        
        do {
            let payloadJsonData = try JSONSerialization.data(withJSONObject:payload, options: [])
            guard let payloadString = String(data: payloadJsonData, encoding: .utf8) else {
                DDLogError("Could not convert JSON data to string")
                return
            }
            let encodedPayloadJsonString = payloadString.wmf_UTF8StringWithPercentEscapes()
            let urlString = "\(EventLoggingService.LoggingEndpoint)?\(encodedPayloadJsonString)"
            guard let url = URL(string: urlString) else {
                DDLogError("Could not convert string '\(urlString)' to URL object")
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")
            urlSession.dataTask(with: request).resume()
            
        } catch let error {
            DDLogError(error.localizedDescription)
        }
    }
}
