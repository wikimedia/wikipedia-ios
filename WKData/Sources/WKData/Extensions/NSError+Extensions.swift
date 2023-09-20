import Foundation

extension NSError {
    var isInternetConnectionError: Bool {
        switch (domain, code) {
        case
            (NSURLErrorDomain, NSURLErrorTimedOut),
            (NSURLErrorDomain, NSURLErrorCannotConnectToHost),
            (NSURLErrorDomain, NSURLErrorNetworkConnectionLost),
            (NSURLErrorDomain, NSURLErrorNotConnectedToInternet):
            return true
        default:
            return false
        }
    }
}
