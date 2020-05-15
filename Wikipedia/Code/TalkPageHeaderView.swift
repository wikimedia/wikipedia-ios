
import UIKit

protocol TalkPageHeaderViewDelegate: class {
    func tappedLink(_ url: URL, headerView: TalkPageHeaderView, sourceView: UIView, sourceRect: CGRect?)
    func tappedIntro(headerView: TalkPageHeaderView)
}

class TalkPageHeaderView: UIView {
    
    weak var delegate: TalkPageHeaderViewDelegate?
    
    struct ViewModel {
        let header: String
        let title: String
        let info: String?
        let intro: String?
    }
    
    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private(set) var titleTextView: UITextView!
    @IBOutlet private(set) var infoLabel: UILabel!
    @IBOutlet private var introTextView: UITextView!
    
    private var viewModel: ViewModel?
    
    private var theme: Theme?
    
    private var hasInfoText: Bool {
        return viewModel?.info != nil
    }
    
    private var hasIntroText: Bool {
        return viewModel?.intro != nil
    }
    
    private var hasTitleText: Bool {
        if let viewModel = viewModel {
            return viewModel.title.count > 0
        }
        
        return false
    }
    
    var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            textAlignmentOverride = semanticContentAttributeOverride == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
            
            headerLabel.semanticContentAttribute = semanticContentAttributeOverride
            titleTextView.semanticContentAttribute = semanticContentAttributeOverride
            infoLabel.semanticContentAttribute = semanticContentAttributeOverride
            introTextView.semanticContentAttribute = semanticContentAttributeOverride
        }
    }
    
    private var textAlignmentOverride: NSTextAlignment = .left {
        didSet {
            headerLabel.textAlignment = textAlignmentOverride
            titleTextView.textAlignment = textAlignmentOverride
            infoLabel.textAlignment = textAlignmentOverride
            introTextView.textAlignment = textAlignmentOverride
        }
    }

    override init(frame: CGRect) {
        assertionFailure("init(frame) not setup for TalkPageHeaderView")
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        infoLabel.numberOfLines = 0
        titleTextView.isEditable = false
        titleTextView.isScrollEnabled = false
        titleTextView.delegate = self
        titleTextView.textContainerInset = UIEdgeInsets.zero
        titleTextView.textContainer.lineFragmentPadding = 0
        introTextView.isEditable = false
        introTextView.isScrollEnabled = false
        introTextView.delegate = self
        introTextView.textContainer.maximumNumberOfLines = 3
        introTextView.textContainer.lineBreakMode = .byTruncatingTail
        introTextView.textContainerInset = UIEdgeInsets.zero
        introTextView.textContainer.lineFragmentPadding = 0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedIntro(sender:)))
        introTextView.addGestureRecognizer(tapGestureRecognizer)
        headerLabel.accessibilityTraits = .header
        titleTextView.accessibilityTraits = .header
        updateFonts(with: traitCollection)
    }
    
    func configure(viewModel: ViewModel) {
        
        self.viewModel = viewModel
        
        if hasInfoText {
            infoLabel.text = viewModel.info
            introTextView.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
        
        headerLabel.text = viewModel.header
        
        if hasTitleText {
            let titleAttributedString = viewModel.title.byAttributingHTML(with: .boldTitle1, boldWeight: .bold, matching: traitCollection, color: titleTextView.textColor, linkColor: theme?.colors.link, handlingSuperSubscripts: true)
            titleTextView.attributedText = titleAttributedString
            titleTextView.isHidden = false
        } else {
            titleTextView.isHidden = true
        }
        
        if let intro = viewModel.intro {
            introTextView.isHidden = false
            setupIntro(text: intro)
        } else {
            introTextView.isHidden = true
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let titleConvertedPoint = self.convert(point, to: titleTextView)
        if titleTextView.point(inside: titleConvertedPoint, with: event) {
            return true
        }
        
        let introConvertedPoint = self.convert(point, to: introTextView)
        if introTextView.point(inside: introConvertedPoint, with: event) {
            return true
        }
        
        return false
    }
    
    private func setupIntro(text: String) {
       introTextView.attributedText = text.byAttributingHTML(with: .footnote, boldWeight: .semibold, matching: traitCollection, color: introTextView.textColor, linkColor: theme?.colors.link, handlingLists: true, handlingSuperSubscripts: true, tagMapping: ["a": "b"])
    }
    
    @objc private func tappedIntro(sender: UITextView) {
        delegate?.tappedIntro(headerView: self)
    }
    
    // MARK - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    open override func setNeedsLayout() {
        maybeUpdateFonts(with: traitCollection)
        super.setNeedsLayout()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.wmf_preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headerLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        titleTextView.font = UIFont.wmf_font(DynamicTextStyle.boldTitle1, compatibleWithTraitCollection: traitCollection)
        infoLabel.font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
        if let intro = viewModel?.intro {
            setupIntro(text: intro)
        }
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
        backgroundColor = theme.colors.paperBackground
    }
}

//MARK: UITextViewDelegate

extension TalkPageHeaderView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, headerView: self, sourceView: textView, sourceRect: textView.frame(of: characterRange))
        return false
    }
}
