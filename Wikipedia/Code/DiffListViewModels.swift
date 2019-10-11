
import Foundation

//tonitodo: rename since unedited lines isn't really a group
protocol DiffListGroupViewModel {
    var theme: Theme { get set }
    var sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) { get set }
    var width: CGFloat { get set }
    var height: CGFloat { get }
    var traitCollection: UITraitCollection { get set }
}

final class DiffListItemHighlightRange {
    
    enum HighlightType {
        case added
        case deleted
    }
    
    let start: Int
    let length: Int
    let type: HighlightType
    
    init(start: Int, length: Int, type: HighlightType) {
        self.start = start
        self.length = length
        self.type = type
    }
}

final class DiffListChangeItemViewModel {
    let text: String
    let highlightedRanges: [DiffListItemHighlightRange]
    let type: DiffListChangeType

    var theme: Theme {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type)
        }
    }
    
    private(set) var textAttributedString: NSAttributedString
    
    init(item: DiffItem, traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType) {
        self.text = item.text
        self.traitCollection = traitCollection
        self.theme = theme
        self.type = type
        
        //tonitodo: clean up
        var highlightedRanges: [DiffListItemHighlightRange] = []
        if let diffHighlightedRanges = item.highlightRanges {
            for diffHighlightedRange in diffHighlightedRanges {
                let start = diffHighlightedRange.start
                let length = diffHighlightedRange.length
                let type = diffHighlightedRange.type == .add ? DiffListItemHighlightRange.HighlightType.added : DiffListItemHighlightRange.HighlightType.deleted
                
                let fromIdx = text.utf8.index(text.utf8.startIndex, offsetBy: start)
                let toIdx = text.utf8.index(fromIdx, offsetBy: length)
                let nsRange = NSRange(fromIdx..<toIdx, in: text)
                
                let highlightedRange = DiffListItemHighlightRange(start: nsRange.location, length: nsRange.length, type: type)
                highlightedRanges.append(highlightedRange)
            }
        }
        
        self.highlightedRanges = highlightedRanges
        
        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type)
    }
    
    private static func calculateAttributedString(with text: String, highlightedRanges: [DiffListItemHighlightRange], traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType) -> NSAttributedString {
        
        let regularFontStyle: DynamicTextStyle = type == .singleRevison ? .callout : .footnote
        let boldFontStyle: DynamicTextStyle = type == .singleRevison ? .boldCallout : .boldFootnote
        
        let font = UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection)
//        let paragraphStyle = NSMutableParagraphStyle()
//        let lineSpacing: CGFloat = 4
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.lineHeightMultiple = font.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        let attributes = [NSAttributedString.Key.font: font]
                          //NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        
        for range in highlightedRanges {
            
            let nsRange = NSRange(location: range.start, length: range.length)
            let highlightColor: UIColor
            
            switch range.type {
            case .added:
                highlightColor = theme.colors.diffHighlightAdd
                
            case .deleted:
                highlightColor = theme.colors.diffHighlightDelete
                let deletedAttributes: [NSAttributedString.Key: Any]  = [
                    NSAttributedString.Key.strikethroughStyle:NSUnderlineStyle.single.rawValue,
                    NSAttributedString.Key.strikethroughColor:UIColor.black
                ]
                mutableAttributedString.addAttributes(deletedAttributes, range: nsRange)
            }
            
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: highlightColor, range: nsRange)
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection), range: nsRange)
        }
        
        return mutableAttributedString
    }
}

//fileprivate extension UIFont
//{
//    func lineSpacingToMatch(lineHeightMultiple: CGFloat) -> CGFloat {
//        return self.lineHeight * (lineHeightMultiple - 1)
//    }
//
//    func lineHeightMultipleToMatch(lineSpacing: CGFloat) -> CGFloat {
//        return 1 + lineSpacing / self.lineHeight
//    }
//}

extension DiffListChangeItemViewModel: Equatable {
    static func == (lhs: DiffListChangeItemViewModel, rhs: DiffListChangeItemViewModel) -> Bool {
        return lhs.highlightedRanges == rhs.highlightedRanges &&
            lhs.text == rhs.text
    }
}

extension DiffListItemHighlightRange: Equatable {
    static func == (lhs: DiffListItemHighlightRange, rhs: DiffListItemHighlightRange) -> Bool {
        return lhs.start == rhs.start &&
            lhs.length == rhs.length &&
            lhs.type == rhs.type
    }
    
}

enum DiffListChangeType {
    case singleRevison
    case compareRevision
}

final class DiffListChangeViewModel: DiffListGroupViewModel {
    
    let type: DiffListChangeType
    let heading: String
    private(set) var headingAttributedString: NSAttributedString
    let items: [DiffListChangeItemViewModel]
    var theme: Theme {
        didSet {
            borderColor = DiffListChangeViewModel.calculateBorderColor(type: type, theme: theme)
            let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
            headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
            
            for item in items {
                item.theme = theme
            }
        }
    }
    var sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
        didSet {
            innerPadding = DiffListChangeViewModel.calculateInnerPadding(sizeClass: sizeClass)
            height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, textPadding: textPadding)
        }
    }
    var traitCollection: UITraitCollection {
        didSet {
            for item in items {
                item.traitCollection = traitCollection
            }
            
            let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
            headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
            height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, textPadding: textPadding)
        }
    }
    
    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing - textPadding.leading - textPadding.trailing
    }
    
    var width: CGFloat {
        didSet {
            height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, textPadding: textPadding)
        }
    }
    
    private(set) var borderColor: UIColor
    private(set) var height: CGFloat = 0
    private(set) var innerPadding: NSDirectionalEdgeInsets
    private(set) var headingPadding: NSDirectionalEdgeInsets
    private(set) var textPadding: NSDirectionalEdgeInsets
    let innerViewClipsToBounds: Bool
    
    init(type: DiffListChangeType, diffItems: [DiffItem], theme: Theme, width: CGFloat, sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass), traitCollection: UITraitCollection) {
        
        self.type = type
        self.theme = theme
        self.sizeClass = sizeClass
        self.width = width
        self.traitCollection = traitCollection
        self.innerViewClipsToBounds = type == .compareRevision
        
        if let firstItemLineNumber = diffItems.first?.lineNumber,
            let lastItemLineNumber = diffItems.last?.lineNumber {
            
            self.heading = String.localizedStringWithFormat(WMFLocalizedString("diff-context-lines-format", value:"Lines %1$d - %2$d", comment:"Label in diff to indicate how many lines a context section encompases. %1$d is replaced by the starting line number and %2$d is replaced by the ending line number"), firstItemLineNumber, lastItemLineNumber)
        } else {
            self.heading = "" //tonitodo: optional would be better
        }
        
        var itemViewModels: [DiffListChangeItemViewModel] = []
        for diffItem in diffItems {
            let changeItemViewModel = DiffListChangeItemViewModel(item: diffItem, traitCollection: traitCollection, theme: theme, type: type)
            itemViewModels.append(changeItemViewModel)
        }
        
        self.items = itemViewModels
        
        borderColor = DiffListChangeViewModel.calculateBorderColor(type: type, theme: theme)
        innerPadding = DiffListChangeViewModel.calculateInnerPadding(sizeClass: sizeClass)
        headingPadding = DiffListChangeViewModel.calculateHeadingPadding(type: type)
        textPadding = DiffListChangeViewModel.calculateTextPadding(type: type)
        
        let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
        headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
        
        height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, textPadding: textPadding)
    }
    
    private static func calculateBorderColor(type: DiffListChangeType, theme: Theme) -> UIColor {
        switch type {
        case .compareRevision:
            return theme.colors.warning
            //headingColor = theme.colors.tagText
        case .singleRevison:
            return theme.colors.paperBackground
            //headingColor = theme.colors.secondaryText
        }
    }
    
    private static func calculateHeadingColor(type: DiffListChangeType, theme: Theme) -> UIColor {
        switch type {
        case .compareRevision:
            return UIColor.white //tonitodo: should this change based on theme
        case .singleRevison:
            return theme.colors.secondaryText
        }
    }
    
    private static func calculateHeadingPadding(type: DiffListChangeType) -> NSDirectionalEdgeInsets {
        switch type {
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: 10, leading: 7, bottom: 10, trailing: 7)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 10, trailing: 0)
        }
    }
    
    private static func calculateTextPadding(type: DiffListChangeType) -> NSDirectionalEdgeInsets {
        switch type {
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
    
    private static func calculateHeadingAttributedString(headingColor: UIColor, text: String, traitCollection: UITraitCollection) -> NSAttributedString {
        
        let font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: headingColor
            ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private static func calculateHeight(items: [DiffListChangeItemViewModel], availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, headingAttributedString: NSAttributedString, headingPadding: NSDirectionalEdgeInsets, textPadding: NSDirectionalEdgeInsets) -> CGFloat {

        var height: CGFloat = 0
        
        for item in items {
            let newHeight = ceil(item.textAttributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
            height += newHeight
        }
        
        //add heading height
        height += headingPadding.top
        height += headingPadding.bottom
        height += ceil(headingAttributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.top
        height += innerPadding.bottom
        height += textPadding.top
        height += textPadding.bottom
        
        return height
    }
    
    private static func calculateInnerPadding(sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass)) -> NSDirectionalEdgeInsets {
        switch (sizeClass.horizontal, sizeClass.vertical) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 10, leading: 50, bottom: 10, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
        }
    }
}

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
    
    var width: CGFloat {
        didSet {
            height = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
            collapsedHeight = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
        }
    }
    var traitCollection: UITraitCollection {
        didSet {
            contextFont = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
            headingFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
            height = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
            collapsedHeight = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
        }
    }
    
    private(set) var height: CGFloat = 0
    private(set) var collapsedHeight: CGFloat = 0
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
    
    var sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
        didSet {
            innerPadding = DiffListContextViewModel.calculateInnerPadding(sizeClass: sizeClass)
            height = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
            collapsedHeight = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
        }
    }
    
    init(diffItems: [DiffItem], isExpanded: Bool, theme: Theme, width: CGFloat, sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass), traitCollection: UITraitCollection) {
        self.isExpanded = isExpanded
        self.theme = theme
        self.sizeClass = sizeClass
        self.width = width
        self.traitCollection = traitCollection
        
        self.items = diffItems.map{ $0.text.count == 0 ? nil : $0.text }
        
        if let firstItemLineNumber = diffItems.first?.lineNumber,
            let lastItemLineNumber = diffItems.last?.lineNumber {
            
            self.heading = String.localizedStringWithFormat(WMFLocalizedString("diff-context-lines-format", value:"Lines %1$d - %2$d", comment:"Label in diff to indicate how many lines a context section encompases. %1$d is replaced by the starting line number and %2$d is replaced by the ending line number"), firstItemLineNumber, lastItemLineNumber)
        } else {
            self.heading = "" //tonitodo: optional would be better
        }
        
        self.contextFont = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        self.headingFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        
        innerPadding = DiffListContextViewModel.calculateInnerPadding(sizeClass: sizeClass)
        
        height = DiffListContextViewModel.calculateExpandedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont, emptyContextLineHeight: emptyContextLineHeight)
        collapsedHeight = DiffListContextViewModel.calculateCollapsedHeight(items: items, heading: heading, availableWidth: availableWidth, innerPadding: innerPadding, contextItemPadding: DiffListContextViewModel.contextItemTextPadding, contextFont: contextFont, headingFont: headingFont)
    }
    
    private static func calculateInnerPadding(sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass)) -> NSDirectionalEdgeInsets {
        switch (sizeClass.horizontal, sizeClass.vertical) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 10, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 0, trailing: 15)
        }
    }
    
    private static func calculateExpandedHeight(items: [String?], heading: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, contextItemPadding: NSDirectionalEdgeInsets, contextFont: UIFont, headingFont: UIFont, emptyContextLineHeight: CGFloat) -> CGFloat {

        var height: CGFloat = 0
        
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
        
        //add heading height

        height += innerPadding.top
        let attributedString = NSAttributedString(string: heading, attributes: [NSAttributedString.Key.font: headingFont])
        height += ceil(attributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.bottom
        height += DiffListContextViewModel.containerStackSpacing
        
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
}

final class DiffListUneditedViewModel: DiffListGroupViewModel {
    private(set) var height: CGFloat = 0
    
    var sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
        didSet {
            innerPadding = DiffListUneditedViewModel.calculateInnerPadding(sizeClass: sizeClass)
            height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
        }
    }
    
    var width: CGFloat {
        didSet {
            height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            font = DiffListUneditedViewModel.calculateTextLabelFont(traitCollection: traitCollection)
            height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
        }
    }
    
    let text: String
    var theme: Theme
    private(set) var font: UIFont
    private(set) var innerPadding: NSDirectionalEdgeInsets
    
    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing
    }
    
    init(numberOfUneditedLines: Int, theme: Theme, width: CGFloat, sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass), traitCollection: UITraitCollection) {
        self.theme = theme
        self.width = width
        self.sizeClass = sizeClass
        self.traitCollection = traitCollection
        self.theme = theme
        self.innerPadding = DiffListUneditedViewModel.calculateInnerPadding(sizeClass: sizeClass)
        self.font = DiffListUneditedViewModel.calculateTextLabelFont(traitCollection: traitCollection)
        
        self.text = String.localizedStringWithFormat(WMFLocalizedString("diff-unedited-lines-format", value:"{{PLURAL:%1$d|%1$d line unedited|%1$d lines unedited}}", comment:"Label in diff to indicate how many lines are not displayed because they were not changed. %1$d is replaced by the number of unedited lines."), numberOfUneditedLines)
        self.height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
    }
    
    private static func calculateInnerPadding(sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass)) -> NSDirectionalEdgeInsets {
        switch (sizeClass.horizontal, sizeClass.vertical) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 10, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 0, trailing: 15)
        }
    }
    
    private static func calculateTextLabelFont(traitCollection: UITraitCollection) -> UIFont {
        return UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    private static func calculateHeight(text: String, availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, font: UIFont) -> CGFloat {

        var height: CGFloat = 0

        height += innerPadding.top
        let attributedString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
        height += ceil(attributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.bottom
        
        return height
    }
}
