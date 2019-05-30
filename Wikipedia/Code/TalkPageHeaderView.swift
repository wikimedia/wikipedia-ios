
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
        let intro: String?
    }
    
    private let headerLabel = UILabel()
    private(set) var titleTextView = UITextView()
    private let infoLabel = UILabel()
    private let introTextView = UITextView()
    private let dividerView = UIView(frame: .zero)
    
    private var viewModel: ViewModel?
    
    private var theme: Theme?
    
    private var hasInfoText: Bool {
        return viewModel?.info != nil
    }
    
    private var hasIntroText: Bool {
        return viewModel?.intro != nil
    }
    
    override func setup() {
        super.setup()
        infoLabel.numberOfLines = 0
        titleTextView.isEditable = false
        titleTextView.isScrollEnabled = false
        titleTextView.delegate = self
        introTextView.isEditable = false
        introTextView.isScrollEnabled = false
        introTextView.delegate = self
        introTextView.textContainer.maximumNumberOfLines = 3
        introTextView.textContainer.lineBreakMode = .byTruncatingTail
        addSubview(headerLabel)
        addSubview(titleTextView)
        addSubview(introTextView)
        addSubview(dividerView)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top - 1, left: layoutMargins.left + 7, bottom: layoutMargins.bottom + 3, right: layoutMargins.right + 7)
        
        let talkOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let contentMaximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let headerFrame = headerLabel.wmf_preferredFrame(at: talkOrigin, maximumWidth: contentMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let titleOrigin = CGPoint(x: adjustedMargins.left - 3, y: headerFrame.maxY + 5)
        let titleFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: contentMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        var finalHeight: CGFloat
        if hasInfoText {
            let infoOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY)
            let infoFrame = infoLabel.wmf_preferredFrame(at: infoOrigin, maximumWidth: contentMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
            
            if hasIntroText {
                let introOrigin = CGPoint(x: adjustedMargins.left - 3, y: infoFrame.maxY + 3)
                let introFrame = introTextView.wmf_preferredFrame(at: introOrigin, maximumWidth: contentMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
                finalHeight = introFrame.maxY + adjustedMargins.bottom
                introTextView.isHidden = false
            } else {
                finalHeight = infoFrame.maxY + 7 + adjustedMargins.bottom
                introTextView.isHidden = true
            }
            
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
        
        let titleFont = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        
        if let titleAttributedString = viewModel.title.wmf_attributedStringFromHTML(with: titleFont, boldFont: titleFont, italicFont: titleFont, boldItalicFont: titleFont, color: titleTextView.textColor, linkColor:theme?.colors.link, withAdditionalBoldingForMatchingSubstring:nil, tagMapping: nil, additionalTagAttributes: nil).wmf_trim() {
            titleTextView.attributedText = titleAttributedString
        }
        
        let introFont = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        let boldIntroFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        let italicIntroFont = UIFont.wmf_font(.italicFootnote, compatibleWithTraitCollection: traitCollection)
        
        if let introAttributedString = viewModel.intro?.wmf_attributedStringFromHTML(with: introFont, boldFont: boldIntroFont, italicFont: italicIntroFont, boldItalicFont: boldIntroFont, color: introTextView.textColor, linkColor:theme?.colors.link, withAdditionalBoldingForMatchingSubstring:nil, tagMapping: nil, additionalTagAttributes: nil).wmf_trim() {
            introTextView.attributedText = introAttributedString
        }
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
        titleTextView.backgroundColor = theme.colors.paperBackground
        headerLabel.textColor = theme.colors.secondaryText
        titleTextView.textColor = theme.colors.primaryText
        infoLabel.textColor = theme.colors.secondaryText
        introTextView.textColor = theme.colors.primaryText
        introTextView.backgroundColor = theme.colors.paperBackground
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
