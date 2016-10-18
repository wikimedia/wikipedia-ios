import UIKit

class InTheNewsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_configureWithDefaultPlaceholder()
    }
    
    static var estimatedRowHeight:CGFloat = 116

    var imageURL: NSURL? {
        didSet {
            guard let URL = imageURL else {
                imageView.wmf_configureWithDefaultPlaceholder()
                imageView.hidden = true
                return
            }
            
            imageView.wmf_setImageWithURL(URL, detectFaces: true, onGPU: true, failure: { (error) in
                self.imageView.hidden = true
                }) { 
                self.imageView.hidden = false
            }
        }
    }
    
    var bodyHTML: String? {
        didSet {
            guard let bodyHTML = bodyHTML else {
                label.text = nil
                return
            }
            var font: UIFont
            if #available(iOS 10.0, *) {
                font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote, compatibleWithTraitCollection: nil)
            } else {
                font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
            }
            let linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
            let attributedString = bodyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
            label.attributedText = attributedString
        }
    }

}
