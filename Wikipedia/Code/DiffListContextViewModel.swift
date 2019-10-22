
import Foundation

final class DiffListContextViewModel: DiffListGroupViewModel {
    let heading: String
    var isExpanded: Bool
    let items: [String?]
    var theme: Theme
    var expandButtonTitle: String {
        return isExpanded ? WMFLocalizedString("diff-context-lines-expanded-button-title", value:"Hide", comment:"Expand button title in diff compare context section when section is in expanded state.") : WMFLocalizedString("diff-context-lines-collapsed-button-title", value:"Show", comment:"Expand button title in diff compare context section when section is in collapsed state.")
    }
    
    private(set) var contextFont: UIFont
    private(set) var headingFont: UIFont
    
    private var _width: CGFloat
    var width: CGFloat {
        get {
            return _width
        }
        set {
            _width = newValue
            expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
            height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
        }
    }
    var traitCollection: UITraitCollection {
        didSet {
            innerPadding = DiffListContextViewModel.calculateInnerPadding(traitCollection: traitCollection)
            contextFont = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
            headingFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        }
    }
    
    private(set) var height: CGFloat = 0
    private(set) var expandedHeight: CGFloat = 0
    private(set) var innerPadding: NSDirectionalEdgeInsets
    
    static let contextItemTextPadding = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    static let contextItemStackSpacing: CGFloat = 5
    static let containerStackSpacing: CGFloat = 15
    
    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing - DiffListContextViewModel.contextItemTextPadding.leading - DiffListContextViewModel.contextItemTextPadding.trailing
    }
    var emptyContextLineHeight: CGFloat {
        return contextFont.pointSize * 1.8
    }
    
    init(diffItems: [DiffItem], isExpanded: Bool, theme: Theme, width: CGFloat, traitCollection: UITraitCollection) {
        self.isExpanded = isExpanded
        self.theme = theme
        self._width = width
        self.traitCollection = traitCollection
        
        self.items = diffItems.map{ $0.text.count == 0 ? nil : $0.text }
        
        if let firstItemLineNumber = diffItems.first?.lineNumber,
            let lastItemLineNumber = diffItems.last?.lineNumber {
            
            if diffItems.count == 1 {
                self.heading = String.localizedStringWithFormat(CommonStrings.diffSingleLineFormat, firstItemLineNumber)
            } else {
                self.heading = String.localizedStringWithFormat(CommonStrings.diffMultiLineFormat, firstItemLineNumber, lastItemLineNumber)
            }
            
        } else {
            self.heading = "" //tonitodo: optional would be better
        }
        
        self.contextFont = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        self.headingFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        
        innerPadding = DiffListContextViewModel.calculateInnerPadding(traitCollection: traitCollection)
        
        expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
        height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
    }
    
    private static func calculateInnerPadding(traitCollection: UITraitCollection) -> NSDirectionalEdgeInsets {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 10, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 0, trailing: 15)
        }
    }
    
    private static func calculateExpandedHeight(items: [String?], heading: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, contextItemPadding: NSDirectionalEdgeInsets, contextFont: UIFont, headingFont: UIFont, emptyContextLineHeight: CGFloat) -> CGFloat {

        var height: CGFloat = 0
        height = calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: contextItemPadding, contextFont: contextFont, headingFont: headingFont)
        
        for item in items {
            
            height += contextItemPadding.top
            
            let itemTextHeight: CGFloat
            if let item = item {
                let attributedString = NSAttributedString(string: item, attributes: [NSAttributedString.Key.font: contextFont])
                itemTextHeight = ceil(attributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
            } else {
                itemTextHeight = emptyContextLineHeight
            }
            
            height += itemTextHeight
            height += contextItemPadding.bottom
            
            height += DiffListContextViewModel.contextItemStackSpacing
        }
        
        return height
    }
    
    private static func calculateCollapsedHeight(items: [String?], heading: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, contextItemPadding: NSDirectionalEdgeInsets, contextFont: UIFont, headingFont: UIFont) -> CGFloat {

        var height: CGFloat = 0
        
        //add heading height

        height += innerPadding.top
        let attributedString = NSAttributedString(string: heading, attributes: [NSAttributedString.Key.font: headingFont])
        height += ceil(attributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.bottom
        height += DiffListContextViewModel.containerStackSpacing
        
        return height
    }
    
    func updateSize(width: CGFloat, traitCollection: UITraitCollection) {
        _width = width
        self.traitCollection = traitCollection
        
        expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
        height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
    }
}
