
import UIKit

public class WMFImageURLActivitySource: NSObject, UIActivityItemSource {

    let info: MWKImageInfo
    
    public required init(info: MWKImageInfo) {
        self.info = info
        super.init()
    }
    
    public func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return NSURL()
    }
    
    public func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        
        var url: NSURL?
        
        if activityType == UIActivityTypePostToTwitter
        || activityType == UIActivityTypePostToWeibo
        || activityType == UIActivityTypePostToTencentWeibo{
            let string = "\(info.filePageURL.absoluteString)?wprov=sfii1"
            url = NSURL(string: string)
        }else {
            url = nil
        }
        
        return url
    }

}
