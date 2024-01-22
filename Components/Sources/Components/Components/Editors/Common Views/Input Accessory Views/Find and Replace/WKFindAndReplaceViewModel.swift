import Foundation

struct WKFindAndReplaceViewModel {

    enum Configuration {
        case findOnly
        case findAndReplace
    }
    
    var currentMatchInfo: String?
    var nextPrevButtonsAreEnabled: Bool = false
    
    let configuration: Configuration = .findAndReplace
    
    mutating func reset() {
        currentMatchInfo = nil
        nextPrevButtonsAreEnabled = false
    }
}
