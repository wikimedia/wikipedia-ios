import WMFComponents

final class DiffListContextItemViewModel {
    private let text: String    
    let accessibilityLabelText: String
    private let semanticContentAttribute: UISemanticContentAttribute
    var theme: Theme {
        didSet {
            self.textAttributedString = DiffListContextItemViewModel.calculateAttributedString(with: text, semanticContentAttribute: semanticContentAttribute, theme: theme, contextFont: contextFont)
        }
    }
    var contextFont: UIFont {
           didSet {
               self.textAttributedString = DiffListContextItemViewModel.calculateAttributedString(with: text, semanticContentAttribute: semanticContentAttribute, theme: theme, contextFont: contextFont)
           }
    }
    
    private(set) var textAttributedString: NSAttributedString
    
    init(text: String, semanticContentAttribute: UISemanticContentAttribute, theme: Theme, contextFont: UIFont) {
        self.text = text
        self.semanticContentAttribute = semanticContentAttribute
        self.theme = theme
        self.contextFont = contextFont
        
        self.textAttributedString = DiffListContextItemViewModel.calculateAttributedString(with: text, semanticContentAttribute: semanticContentAttribute, theme: theme, contextFont: contextFont)

        let diffContextualLine = WMFLocalizedString("diff-unchanged-contextual-line", value: "Contextual line, unchanged: %1$@", comment: "Text read by VoiceOver in diffs that indicates information about the forthcoming content. %1$@ will be replaced with that content.")
        self.accessibilityLabelText = String.localizedStringWithFormat(diffContextualLine, text) 
    }


    private static func calculateAttributedString(with text: String, semanticContentAttribute: UISemanticContentAttribute, theme: Theme, contextFont: UIFont) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        let lineSpacing: CGFloat = 4
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = contextFont.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        switch semanticContentAttribute {
        case .forceRightToLeft:
            paragraphStyle.alignment = .right
        default:
            paragraphStyle.alignment = .left
        }
        let attributes = [NSAttributedString.Key.font: contextFont,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}

extension DiffListContextItemViewModel: Equatable {
    static func == (lhs: DiffListContextItemViewModel, rhs: DiffListContextItemViewModel) -> Bool {
        return lhs.text == rhs.text
    }
}

final class DiffListContextViewModel: DiffListGroupViewModel {
    let heading: String
    var isExpanded: Bool
    let items: [DiffListContextItemViewModel?]
    var theme: Theme {
        didSet {
            for item in items {
                item?.theme = theme
            }
        }
    }
    var expandButtonTitle: String {
        return isExpanded ? WMFLocalizedString("diff-context-lines-expanded-button-title", value:"Hide", comment:"Expand button title in diff compare context section when section is in expanded state.") : WMFLocalizedString("diff-context-lines-collapsed-button-title", value:"Show", comment:"Expand button title in diff compare context section when section is in collapsed state.")
    }

    var expandButtonImage: UIImage {
        guard let image = UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down") else {
            fatalError("SF Symbol not found")
        }

        return image
    }
    
    private(set) var contextFont: UIFont {
        didSet {
            for item in items {
                item?.contextFont = contextFont
            }
        }
    }
    private(set) var headingFont: UIFont
    
    private var _width: CGFloat
    var width: CGFloat {
        get {
            return _width
        }
        set {
            _width = newValue
            expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight, headerHeight: 40)
            height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, headerHeight: 40)
        }
    }
    var traitCollection: UITraitCollection {
        didSet {
            innerPadding = DiffListContextViewModel.calculateInnerPadding(traitCollection: traitCollection)
            contextFont = WMFFont.for(contextDynamicTextStyle, compatibleWith: traitCollection)
            headingFont = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        }
    }
    
    private let contextDynamicTextStyle = WMFFont.subheadline
    private(set) var height: CGFloat = 0
    private(set) var expandedHeight: CGFloat = 0
    private(set) var innerPadding: NSDirectionalEdgeInsets
    
    static let contextItemTextPadding = NSDirectionalEdgeInsets(top: 15, leading: 8, bottom: 0, trailing: 8)
    static let contextItemStackSpacing: CGFloat = 5
    static let containerStackSpacing: CGFloat = 15
    private(set) var headerHeight: CGFloat = 35

    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing - DiffListContextViewModel.contextItemTextPadding.leading - DiffListContextViewModel.contextItemTextPadding.trailing
    }
    var emptyContextLineHeight: CGFloat {
        return contextFont.pointSize * 1.8
    }
    
    init(diffItems: [TransformDiffItem], isExpanded: Bool, theme: Theme, width: CGFloat, traitCollection: UITraitCollection, semanticContentAttribute: UISemanticContentAttribute) {

        self.isExpanded = isExpanded
        self.theme = theme
        self._width = width
        self.traitCollection = traitCollection
        
        if let firstItemLineNumber = diffItems.first?.lineNumber,
            let lastItemLineNumber = diffItems.last?.lineNumber {
            
            if diffItems.count == 1 {
                self.heading = String.localizedStringWithFormat(CommonStrings.diffSingleLineFormat, firstItemLineNumber)
            } else {
                self.heading = String.localizedStringWithFormat(CommonStrings.diffMultiLineFormat, firstItemLineNumber, lastItemLineNumber)
            }
            
        } else {
            self.heading = "" // tonitodo: optional would be better
        }
        
        let contextFont = WMFFont.for(contextDynamicTextStyle, compatibleWith: traitCollection)

        self.items = diffItems.map({ (item) -> DiffListContextItemViewModel? in
            if item.text.isEmpty {
                return nil
            }
            
            return DiffListContextItemViewModel(text: item.text, semanticContentAttribute: semanticContentAttribute, theme: theme, contextFont: contextFont)
        })
        
        self.contextFont = contextFont
        self.headingFont = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)

        innerPadding = DiffListContextViewModel.calculateInnerPadding(traitCollection: traitCollection)
        
        expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight, headerHeight: headerHeight)
        height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, headerHeight: headerHeight)
    }
    
    private static func calculateInnerPadding(traitCollection: UITraitCollection) -> NSDirectionalEdgeInsets {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        }
    }
    
    private static func calculateExpandedHeight(items: [DiffListContextItemViewModel?], heading: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, contextItemPadding: NSDirectionalEdgeInsets, contextFont: UIFont, headingFont: UIFont, emptyContextLineHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {

        var height: CGFloat = 0
        height = calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: contextItemPadding, contextFont: contextFont, headingFont: headingFont, headerHeight: headerHeight)

        for (index, item) in items.enumerated() {
            
            height += contextItemPadding.top
            
            let itemTextHeight: CGFloat
            if let item = item {
                itemTextHeight = ceil(item.textAttributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
            } else {
                itemTextHeight = emptyContextLineHeight
            }
            
            height += itemTextHeight
            
            if index < (items.count - 1) {
                height += DiffListContextViewModel.contextItemStackSpacing
            }
        }
        
        height += DiffListContextViewModel.containerStackSpacing
        
        return height
    }
    
    private static func calculateCollapsedHeight(items: [DiffListContextItemViewModel?], heading: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, contextItemPadding: NSDirectionalEdgeInsets, contextFont: UIFont, headingFont: UIFont, headerHeight: CGFloat) -> CGFloat {

        var height: CGFloat = 0

        height += innerPadding.top
        let attributedString = NSAttributedString(string: heading, attributes: [NSAttributedString.Key.font: headingFont])
        height += ceil(attributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.bottom

        height += (headerHeight / 2)

        return height
    }
    
    func updateSize(width: CGFloat, traitCollection: UITraitCollection) {
        _width = width
        self.traitCollection = traitCollection
        
        expandedHeight = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight, headerHeight: headerHeight)
        height = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, headerHeight: headerHeight)
    }
}
