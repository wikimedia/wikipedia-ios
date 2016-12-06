import UIKit

class InTheNewsCollectionViewCell: WMFExploreCollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let textStyle = UIFontTextStyleSubheadline
    var font = UIFont.preferredFontForTextStyle(textStyle)
    var linkFont = UIFont.preferredFontForTextStyle(textStyle)
    
    static var estimatedRowHeight:CGFloat = 86

    var imageURL: NSURL? {
        didSet {
            guard let URL = imageURL else {
                imageView.wmf_placeholderView.alpha = 1
                return
            }
            
            imageView.wmf_setImageWithURL(URL,
                                          detectFaces: true,
                                          onGPU: true,
                                          failure: { (error) in
                                            dispatch_async(dispatch_get_main_queue(), { () in
                                                self.imageView.wmf_placeholderView.alpha = 1
                                            })
                                          },
                                          success: { () in  })
        }
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        font = UIFont.preferredFontForTextStyle(InTheNewsCollectionViewCell.textStyle)
        linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
        updateBodyHTMLStyle()
    }
    
    func updateBodyHTMLStyle() {
        guard let bodyHTML = bodyHTML else {
            label.text = nil
            return
        }
        let attributedString = bodyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
        label.attributedText = attributedString
    }
    
    var bodyHTML: String? {
        didSet {
            updateBodyHTMLStyle()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.wmf_configureSubviewsForDynamicType()
    }
}
