import Foundation
import QuartzCore

extension UINavigationBar {
    
    func wmf_applyGalleryTopGradientBackground() {
        if (!CGRectIsNull(bounds)){
            if (CGRectGetWidth(bounds) > 0 && CGRectGetHeight(bounds) > 0){
                setBackgroundImage(wmf_galleryTopGradientBackgroundImage(), forBarMetrics: .Default)
            }
        }
    }
    
    func wmf_galleryTopGradientBackgroundImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations:[CGFloat] = [0.0, 1.0]
        let bottom = UIColor.clearColor().CGColor
        let top = UIColor.blackColor().CGColor
        
        let gradient = CGGradientCreateWithColors(colorSpace, [top, bottom], locations)
        
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 0, y: CGRectGetHeight(bounds))
        
        CGContextDrawLinearGradient(context!, gradient!, start, end, [])
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage!
    }
}

