
import UIKit

protocol ReplyButtonFooterViewDelegate: class {
    func tappedReply(from view: TalkPageReplyFooterView)
    func composeTextDidChange(text: String?)
    var collectionViewFrame: CGRect { get }
}

class TalkPageReplyFooterView: SizeThatFitsReusableView {
    let composeView = TalkPageReplyComposeView(frame: .zero)
    weak var delegate: ReplyButtonFooterViewDelegate?
    private let replyButton = ActionButton(frame: .zero)
    let dividerView = UIView(frame: .zero)
    private let divComposeSpacing = CGFloat(10)
    
    var showingCompose = false {
        didSet {
            replyButton.isHidden = showingCompose
            composeView.isHidden = !showingCompose
        }
    }
    
    var composeButtonIsDisabled = true {
        didSet {
            replyButton.isEnabled = !composeButtonIsDisabled
        }
    }
    
    private var adjustedMargins: UIEdgeInsets {
        return UIEdgeInsets(top: layoutMargins.top + 25, left: layoutMargins.left + 5, bottom: layoutMargins.bottom, right: layoutMargins.right + 5)
    }
    
    var composeTextView: ThemeableTextView {
        return composeView.composeTextView
    }
    
    func resetCompose() {
        composeView.resetCompose()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {

        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        
        let maximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        let dividerHeight = CGFloat(1)
        
        if !showingCompose {
            let divReplySpacing = CGFloat(35)
            let replyButtonBottomMargin = CGFloat(65)
            let buttonOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top + dividerHeight + divReplySpacing)
            
            var replyButtonFrame = replyButton.wmf_preferredFrame(at: buttonOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy:semanticContentAttribute, apply: apply)
            
            //update frame to be centered
            if (apply) {
                replyButtonFrame.origin = CGPoint(x: (size.width / 2) - (replyButtonFrame.width / 2), y: replyButtonFrame.origin.y)
                replyButton.frame = replyButtonFrame
                dividerView.frame = CGRect(x: 0, y: adjustedMargins.top, width: size.width, height: dividerHeight)
            }
            
            
            let finalHeight = adjustedMargins.top + dividerHeight + divReplySpacing + replyButtonFrame.height + replyButtonBottomMargin + adjustedMargins.bottom
            
            return CGSize(width: size.width, height: finalHeight)
        } else {
            let composeViewOrigin = CGPoint(x: 0, y: adjustedMargins.top + dividerHeight + divComposeSpacing)
            
            composeView.layoutMargins = layoutMargins
            let composeViewSize = composeView.sizeThatFits(size, apply: apply)
            
            let composeViewFrame = CGRect(origin: composeViewOrigin, size: composeViewSize)
            
            if (apply) {
                composeView.frame = composeViewFrame
                dividerView.frame = CGRect(x: 0, y: adjustedMargins.top, width: size.width, height: dividerHeight)
            }
            
            let finalHeight = adjustedMargins.top + dividerHeight + divComposeSpacing + composeViewSize.height + adjustedMargins.bottom
            
            return CGSize(width: size.width, height: finalHeight)
        }
    }
    
    @objc private func tappedReply() {
        delegate?.tappedReply(from: self)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        replyButton.updateFonts(with: traitCollection)
    }
 
    override func setup() {
        
        replyButton.setTitle(WMFLocalizedString("talk-pages-reply-button-title", value: "Reply to this discussion", comment: "Text displayed in a reply button for replying to a talk page topic thread."), for: .normal)
        replyButton.addTarget(self, action: #selector(tappedReply), for: .touchUpInside)
        addSubview(replyButton)
        addSubview(dividerView)
        composeView.isHidden = true
        composeView.delegate = self
        addSubview(composeView)
        super.setup()
    }
}

//MARK: Themeable

extension TalkPageReplyFooterView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        dividerView.backgroundColor = theme.colors.border
        replyButton.apply(theme: theme)
        composeView.apply(theme: theme)
    }
}

//MARK: TalkPageReplyComposeViewDelegate

extension TalkPageReplyFooterView: TalkPageReplyComposeViewDelegate {
    func composeTextDidChange(text: String?) {
        delegate?.composeTextDidChange(text: text)
    }
    
    var collectionViewFrame: CGRect {
        return delegate?.collectionViewFrame ?? .zero
    }
}
