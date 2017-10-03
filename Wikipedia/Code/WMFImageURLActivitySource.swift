import UIKit
import WMF

open class WMFImageURLActivitySource: NSObject, UIActivityItemSource {

    let info: MWKImageInfo
    
    public required init(info: MWKImageInfo) {
        self.info = info
        super.init()
    }
    
    open func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL(string: "") as Any
    }
    
    open func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        
        var url: URL?
        
        if activityType == UIActivityType.postToTwitter
        || activityType == UIActivityType.postToWeibo
        || activityType == UIActivityType.postToTencentWeibo{
            url = info.filePageURL?.wmf_URLForImageSharing
        }else {
            url = nil
        }
        
        return url
    }

}
