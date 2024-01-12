import Foundation

struct WKFindAndReplaceViewModel {

    enum Configuration {
        case findOnly
        case findAndReplace
    }
    
    var findText: String?
    var currentMatchInfo: String?
    
    let configuration: Configuration = .findAndReplace
    
    mutating func reset() {
        findText = nil
        currentMatchInfo = nil
    }
}
