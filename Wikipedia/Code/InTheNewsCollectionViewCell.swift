import UIKit

class InTheNewsCollectionViewCell: WMFExploreCollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static var estimatedRowHeight:CGFloat = 86

    var imageURL: NSURL? {
        didSet {
            guard let URL = imageURL else {
                imageView.wmf_configureWithDefaultPlaceholder()
                return
            }
            
            imageView.wmf_setImageWithURL(URL, detectFaces: true, onGPU: true, failure: { (error) in self.imageView.wmf_configureWithDefaultPlaceholder() }) { }
        }
    }
    
    var bodyHTML: String? {
        didSet {
            guard let bodyHTML = bodyHTML else {
                label.text = nil
                return
            }
            let font = UIFont.systemFontOfSize(14) // fixed font size until the rest of the app supports dynamic type
            
//            var font: UIFont
//            if #available(iOS 10.0, *) {
//                font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote, compatibleWithTraitCollection: nil)
//            } else {
//                font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
//            }
            let linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
            let attributedString = bodyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
            label.attributedText = attributedString
        }
    }

}
