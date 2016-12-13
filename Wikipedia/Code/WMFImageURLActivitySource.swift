import UIKit

open class WMFImageURLActivitySource: NSObject, UIActivityItemSource {

    let info: MWKImageInfo
    
    public required init(info: MWKImageInfo) {
        self.info = info
        super.init()
    }
    
    open func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL()
    }
    
    open func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        
        var url: URL?
        
        if activityType == UIActivityType.postToTwitter
        || activityType == UIActivityType.postToWeibo
        || activityType == UIActivityType.postToTencentWeibo{
            let string = "\(info.filePageURL.absoluteString)?wprov=sfii1"
            url = URL(string: string)
        }else {
            url = nil
        }
        
        return url
    }

}
