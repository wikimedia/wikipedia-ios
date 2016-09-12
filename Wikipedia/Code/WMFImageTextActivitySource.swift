import UIKit

public class WMFImageTextActivitySource: NSObject, UIActivityItemSource  {

    let info: MWKImageInfo
    
    public required init(info: MWKImageInfo) {
        self.info = info
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return String()
    }
    
    public func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        
        var text: String?

        if activityType == UIActivityTypePostToTwitter {
            text = localizedStringForKeyFallingBackOnEnglish("share-on-twitter-sign-off")
        }else if activityType == UIActivityTypePostToFacebook ||
        activityType == UIActivityTypeMail ||
        activityType == UIActivityTypePostToFlickr {
            text = info.filePageURL.absoluteString
        }else {
            text = nil
        }
        
        return text
    }
    
}
