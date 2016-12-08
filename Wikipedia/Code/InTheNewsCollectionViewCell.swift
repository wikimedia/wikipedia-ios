import UIKit

class InTheNewsCollectionViewCell: WMFExploreCollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let textStyle = UIFontTextStyleSubheadline
    var font = UIFont.preferredFontForTextStyle(textStyle)
    var linkFont = UIFont.preferredFontForTextStyle(textStyle)
    
    static var estimatedRowHeight:CGFloat = 86
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_showPlaceholder()
    }
    
    var imageURL: NSURL? {
        didSet {
            imageView.wmf_showPlaceholder()
            guard let URL = imageURL else {
                return
            }
            
            imageView.wmf_setImageWithURL(URL,
                                          detectFaces: true,
                                          onGPU: true,
                                          failure: { (error) in
                                            dispatch_async(dispatch_get_main_queue(), { () in
                                                self.imageView.wmf_showPlaceholder()
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
        wmf_configureSubviewsForDynamicType()
    }
}
