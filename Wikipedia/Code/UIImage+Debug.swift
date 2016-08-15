import Foundation

extension UIImage {
    var wmf_frame: CGRect {
        return CGRectMake(0, 0, self.size.width, self.size.height)
    }

    func wmf_fillCurrentContext() {
        self.drawInRect(wmf_frame)
    }

    func wmf_imageByDrawingInContext(draw: ()->Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        draw()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
