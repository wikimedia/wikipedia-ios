public extension NSTextAttachment {
    func setImageHeight(_ height: CGFloat, font: UIFont) {
        guard let image = image else { return }
        
        let ratio = image.size.width / image.size.height
        let mid = font.descender + font.capHeight
        
        bounds = CGRect(x: bounds.origin.x, y: font.descender - height / 2 + mid + 2, width: ratio * height, height: height)
    }
}
