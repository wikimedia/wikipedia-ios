import Foundation

extension UIImage {
    var wmf_frame: CGRect {
        return CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
    }

    func wmf_fillCurrentContext() {
        self.draw(in: wmf_frame)
    }

    func wmf_imageByDrawingInContext(_ draw: ()->Void) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        draw()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}
