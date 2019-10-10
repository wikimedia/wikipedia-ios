
import Foundation

protocol DiffListGroupViewModel {
    var theme: Theme { get set }
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

    var theme: Theme {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme)
        }
    }
    
    private(set) var textAttributedString: NSAttributedString
    
    init(text: String, highlightedRanges: [DiffListItemHighlightRange], traitCollection: UITraitCollection, theme: Theme) {
        self.text = text
        self.highlightedRanges = highlightedRanges
        self.traitCollection = traitCollection
        self.theme = theme
        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme)
    }
    
    private static func calculateAttributedString(with text: String, highlightedRanges: [DiffListItemHighlightRange], traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        
        let font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
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
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection), range: nsRange)
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
    
    init(type: DiffListChangeType, heading: String, items: [DiffListChangeItemViewModel], theme: Theme, width: CGFloat, sizeClass: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass), traitCollection: UITraitCollection) {
        
        self.type = type
        self.heading = heading
        self.items = items
        self.theme = theme
        self.sizeClass = sizeClass
        self.width = width
        self.traitCollection = traitCollection
        self.innerViewClipsToBounds = type == .compareRevision
        
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
            let attributes = item.textAttributedString.attributes(at: 0, effectiveRange: nil)
            height += ceil((item.text as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil).height)
        }
        
        //add heading height
        height += headingPadding.top
        height += headingPadding.bottom
        let attributes = headingAttributedString.attributes(at: 0, effectiveRange: nil)
        height += ceil((headingAttributedString.string as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil).height)
        
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
    let lines: String
    var isExpanded: Bool
    let items: [String]
    var theme: Theme
    
    init(lines: String, isExpanded: Bool, items: [String], theme: Theme) {
        self.lines = lines
        self.isExpanded = isExpanded
        self.items = items
        self.theme = theme
    }
}

final class DiffListUneditedViewModel: DiffListGroupViewModel {
    let numberOfUneditedLines: Int
    var theme: Theme
    
    init(numberOfUneditedLines: Int, theme: Theme) {
        self.numberOfUneditedLines = numberOfUneditedLines
        self.theme = theme
    }
}
