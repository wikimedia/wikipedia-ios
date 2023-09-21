import Foundation

struct WKFindAndReplaceViewModel {

    enum Configuration {
        case findOnly
        case findAndReplace
    }
    
    let configuration: Configuration = .findAndReplace
}
