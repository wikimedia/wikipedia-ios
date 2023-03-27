import Foundation
import UIKit

protocol OpenLocationServiceProvider {
    var openLocationService: OpenLocationService { get }
}

protocol OpenLocationService {
    func open(location: Location)
}

final class OpenLocationServiceImpl: OpenLocationService {
    func open(location: Location) {
        /// opens location as deeplink for wikipedia app
        if let url = URL(string: "wikipedia://places?WMFLocation=\(location.lat),\(location.long)") {
            UIApplication.shared.open(url)
        }
    }
}
