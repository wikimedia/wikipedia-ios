import UIKit

open class WMFImageTextActivitySource: NSObject, UIActivityItemSource  {

    let info: MWKImageInfo
    
    public required init(info: MWKImageInfo) {
        self.info = info
        super.init()
    }
    
    open func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return String()
    }
    
    open func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        
        var text: String?

        if activityType == UIActivityType.postToTwitter {
            text = WMFLocalizedString("share-on-twitter-sign-off", value:"via @Wikipedia", comment:"Text placed at the end of a tweet when sharing. Contains the wikipedia twitter handle")
        }else if activityType == UIActivityType.postToFacebook ||
        activityType == UIActivityType.mail ||
        activityType == UIActivityType.postToFlickr {
            text = info.filePageURL?.absoluteString
        }else {
            text = nil
        }
        
        return text
    }
    
}
