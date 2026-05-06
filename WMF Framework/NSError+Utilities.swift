import Foundation
import WMFNativeLocalizations

public extension NSError {
    func alertMessage() -> String {
        if self.wmf_isNetworkConnectionError() {
            return CommonStrings.noInternetConnection
        } else {
            return self.localizedDescription
        }
    }
}
