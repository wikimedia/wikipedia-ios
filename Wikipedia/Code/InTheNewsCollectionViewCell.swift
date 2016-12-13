import UIKit

class InTheNewsCollectionViewCell: WMFExploreCollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    static let textStyle = UIFontTextStyle.subheadline
    var font = UIFont.preferredFont(forTextStyle: textStyle)
    var linkFont = UIFont.preferredFont(forTextStyle: textStyle)
    
    static var estimatedRowHeight:CGFloat = 86
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_showPlaceholder()
    }
    
    var imageURL: URL? {
        didSet {
            imageView.wmf_showPlaceholder()
            guard let URL = imageURL else {
                return
            }
            
            imageView.wmf_setImage(with: URL,
                                          detectFaces: true,
                                          onGPU: true,
                                          failure: { (error) in
                                            DispatchQueue.main.async(execute: { () in
                                                self.imageView.wmf_showPlaceholder()
                                            })
                                          },
                                          success: { () in  })
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        font = UIFont.preferredFont(forTextStyle: InTheNewsCollectionViewCell.textStyle)
        linkFont = UIFont.boldSystemFont(ofSize: font.pointSize)
        updateBodyHTMLStyle()
    }
    
    func updateBodyHTMLStyle() {
        guard let bodyHTML = bodyHTML else {
            label.text = nil
            return
        }
        let attributedString = bodyHTML.wmf_attributedStringByRemovingHTML(with: font, linkFont: linkFont)
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
