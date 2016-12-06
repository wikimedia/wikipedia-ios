import UIKit

class InTheNewsCollectionViewCell: WMFExploreCollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
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
    
    var bodyHTML: String? {
        didSet {
            guard let bodyHTML = bodyHTML else {
                label.text = nil
                return
            }
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            var linkFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)

            // Above UIContentSizeCategoryExtraExtraExtraLarge the UIFontTextStyleBody and UIFontTextStyleHeadline preferred font sizes diverge.
            // In such cases don't use a different linkFont otherwise it looks super weird.
            if font.pointSize != linkFont.pointSize {
                linkFont = font
            }
            
            let attributedString = bodyHTML.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
            label.attributedText = attributedString
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.wmf_configureSubviewsForDynamicType()
    }
}
