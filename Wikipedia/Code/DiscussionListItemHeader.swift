
import UIKit

class DiscussionListItemHeader: SizeThatFitsReusableView {
    private let talkLabel = UILabel()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let dividerView = UIView(frame: .zero)
    
    override func setup() {
        super.setup()
        addSubview(talkLabel)
        addSubview(titleLabel)
        addSubview(infoLabel)
        addSubview(dividerView)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left + 7, bottom: layoutMargins.bottom + 22, right: layoutMargins.right + 7)
        
        let talkOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let labelMaximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let talkFrame = talkLabel.wmf_preferredFrame(at: talkOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: talkFrame.maxY + 15)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let infoOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + 10)
        let infoFrame = infoLabel.wmf_preferredFrame(at: infoOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let finalHeight = infoFrame.maxY + adjustedMargins.bottom
        
        if (apply) {
            dividerView.frame = CGRect(x: 0, y: finalHeight - 1, width: size.width, height: 1)
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(title: String, languageCode: String) {
        talkLabel.text = WMFLocalizedString("talk-page-title-user-talk", value: "User Talk", comment: "This title label is displayed at the top of a talk page discussion list. It represents the kind of talk page the user is viewing.").localizedUppercase
        titleLabel.text = title
        
        let languageWikiFormat = WMFLocalizedString("talk-page-info-active-conversations", value: "Active conversations on %1$@", comment: "This information label is displayed at the top of a talk page discussion list. %1$@ is replaced by the language wiki they are using ('English Wikipedia').")
        
        //todo: fix language wiki text
        var languageWiki: String
        if languageCode == "en" {
            languageWiki = "English Wikipedia"
        } else {
            languageWiki = ""
        }
        
        infoLabel.text = NSString.localizedStringWithFormat(languageWikiFormat as NSString, languageWiki) as String
        
        updateFonts(with: traitCollection)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        talkLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(DynamicTextStyle.boldTitle2, compatibleWithTraitCollection: traitCollection)
        infoLabel.font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    
}

extension DiscussionListItemHeader: Themeable {
    func apply(theme: Theme) {
        talkLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.primaryText
        infoLabel.textColor = theme.colors.secondaryText
        dividerView.backgroundColor = theme.colors.border
        backgroundColor = theme.colors.paperBackground
    }
}
