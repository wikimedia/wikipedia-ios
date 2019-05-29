
import UIKit

protocol TalkPageHeaderViewDelegate: class {
    func tappedLink(_ url: URL, cell: TalkPageHeaderView)
}

class TalkPageHeaderView: SizeThatFitsReusableView {
    
    weak var delegate: TalkPageHeaderViewDelegate?
    
    struct ViewModel {
        let header: String
        let title: String
        let info: String?
    }
    
    private let headerLabel = UILabel()
    private(set) var titleTextView = UITextView()
    private let infoLabel = UILabel()
    private let dividerView = UIView(frame: .zero)
    
    private var viewModel: ViewModel?
    
    private var theme: Theme?
    
    private var hasInfoText: Bool {
        return viewModel?.info != nil
    }
    
    override func setup() {
        super.setup()
        infoLabel.numberOfLines = 0
        titleTextView.isEditable = false
        titleTextView.isScrollEnabled = false
        titleTextView.delegate = self
        addSubview(headerLabel)
        addSubview(titleTextView)
        addSubview(dividerView)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top - 1, left: layoutMargins.left + 7, bottom: layoutMargins.bottom + 21, right: layoutMargins.right + 7)
        
        let talkOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let textViewMaximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let headerFrame = headerLabel.wmf_preferredFrame(at: talkOrigin, maximumWidth: textViewMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: headerFrame.maxY + 15)
        let titleFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: textViewMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        var finalHeight: CGFloat
        if hasInfoText {
            let infoOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + 7)
            let infoFrame = infoLabel.wmf_preferredFrame(at: infoOrigin, maximumWidth: textViewMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
            finalHeight = infoFrame.maxY + adjustedMargins.bottom
        } else {
            finalHeight = titleFrame.maxY + adjustedMargins.bottom
        }
        
        if (apply) {
            dividerView.frame = CGRect(x: 0, y: finalHeight - 1, width: size.width, height: 1)
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: ViewModel) {
        
        self.viewModel = viewModel
        
        if hasInfoText && infoLabel.superview == nil {
            addSubview(infoLabel)
            infoLabel.text = viewModel.info
        }
        
        headerLabel.text = viewModel.header

        //also todo: need to add intro text truncated to 3 lines
        
        let font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        
        if let attributedString = viewModel.title.wmf_attributedStringFromHTML(with: font, boldFont: font, italicFont: font, boldItalicFont: font, color: titleTextView.textColor, linkColor:theme?.colors.link, withAdditionalBoldingForMatchingSubstring:nil, tagMapping: nil, additionalTagAttributes: nil).wmf_trim() {
            titleTextView.attributedText = attributedString
        }
        
        updateFonts(with: traitCollection)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        headerLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        titleTextView.font = UIFont.wmf_font(DynamicTextStyle.boldTitle1, compatibleWithTraitCollection: traitCollection)
        infoLabel.font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    
}

extension TalkPageHeaderView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        headerLabel.textColor = theme.colors.secondaryText
        titleTextView.textColor = theme.colors.primaryText
        infoLabel.textColor = theme.colors.secondaryText
        dividerView.backgroundColor = theme.colors.border
        backgroundColor = theme.colors.paperBackground
    }
}

//MARK: UITextViewDelegate

extension TalkPageHeaderView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, cell: self)
        return false
    }
}
