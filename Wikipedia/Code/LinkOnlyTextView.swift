//https://stackoverflow.com/a/47913329

import Foundation

class LinkOnlyTextView: UITextView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let glyphIndex = self.layoutManager.glyphIndex(for: point, in: self.textContainer)
        
        //Ensure the glyphIndex actually matches the point and isn't just the closest glyph to the point
        let glyphRect = self.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: self.textContainer)
        
        if glyphIndex < self.textStorage.length,
            glyphRect.contains(point),
            self.textStorage.attribute(NSAttributedString.Key.link, at: glyphIndex, effectiveRange: nil) != nil {
            
            return true
        } else {
            return false
        }
    }
}
