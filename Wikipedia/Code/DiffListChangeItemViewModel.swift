
import Foundation

final class DiffListChangeItemViewModel {
    let text: String
    let highlightedRanges: [DiffHighlightRange]
    let type: DiffListChangeType
    let diffItemType: DiffItemType
    let textAlignment: NSTextAlignment
    let moveInfo: TransformMoveInfo?
    private(set) var textPadding: NSDirectionalEdgeInsets
    private let semanticContentAttribute: UISemanticContentAttribute
    
    private(set) var hasShadedBackgroundView: Bool
    private(set) var inBetweenSpacing: CGFloat?

    var theme: Theme {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, semanticContentAttribute: semanticContentAttribute)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, semanticContentAttribute: semanticContentAttribute)
        }
    }
    
    private(set) var textAttributedString: NSAttributedString?
    
    init(firstRevisionText: String, traitCollection: UITraitCollection, theme: Theme, semanticContentAttribute: UISemanticContentAttribute) {
        let text = firstRevisionText
        let theme = theme
        self.text = text
        self.traitCollection = traitCollection
        self.theme = theme
        let type = DiffListChangeType.singleRevison
        let diffItemType = DiffItemType.addLine
        self.type = type
        self.diffItemType = diffItemType
        self.moveInfo = nil
        let semanticContentAttribute = semanticContentAttribute
        self.semanticContentAttribute = semanticContentAttribute
        
        let highlightedRanges = [DiffHighlightRange(start: 0, length: text.count, type: .add)]
        self.highlightedRanges = highlightedRanges
        self.textAlignment = .natural
        let textPaddingAndInBetweenSpacing = DiffListChangeItemViewModel.calculateTextPaddingAndInBetweenSpacing(type: type, diffItemType: diffItemType, nextMiddleItem: nil)
        self.textPadding =  textPaddingAndInBetweenSpacing.0
        self.inBetweenSpacing = nil
        self.hasShadedBackgroundView = false
        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: nil, semanticContentAttribute: semanticContentAttribute)
    }
    
    init(item: TransformDiffItem, traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, nextMiddleItem: TransformDiffItem?, semanticContentAttribute: UISemanticContentAttribute) {
        self.text = item.text

        self.traitCollection = traitCollection
        self.theme = theme
        self.type = type
        self.diffItemType = diffItemType

        self.moveInfo = item.moveInfo
        self.semanticContentAttribute = semanticContentAttribute
        
        //account for utf8 offsets in highlighted ranges
        var convertedHighlightedRanges: [DiffHighlightRange] = []
        if let diffHighlightedRanges = item.highlightRanges {
            for diffHighlightedRange in diffHighlightedRanges {
                let start = diffHighlightedRange.start
                let length = diffHighlightedRange.length
                let type = diffHighlightedRange.type
                
                let fromIdx = text.utf8.index(text.utf8.startIndex, offsetBy: start)
                let toIdx = text.utf8.index(fromIdx, offsetBy: length)
                let nsRange = NSRange(fromIdx..<toIdx, in: text)
                
                let highlightedRange = DiffHighlightRange(start: nsRange.location, length: nsRange.length, type: type)
                convertedHighlightedRanges.append(highlightedRange)
            }
        }
        
        self.highlightedRanges = convertedHighlightedRanges

        textAlignment = diffItemType == .moveSource ? .center : .natural
        
        let textPaddingAndInBetweenSpacing = DiffListChangeItemViewModel.calculateTextPaddingAndInBetweenSpacing(type: type, diffItemType: diffItemType, nextMiddleItem: nextMiddleItem)
        self.textPadding =  textPaddingAndInBetweenSpacing.0
        self.inBetweenSpacing = textPaddingAndInBetweenSpacing.1
        
        hasShadedBackgroundView = (diffItemType == .moveSource || diffItemType == .moveDestination)

        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: item.moveInfo, semanticContentAttribute: semanticContentAttribute)
    }
    
    private static func calculateTextPaddingAndInBetweenSpacing(type: DiffListChangeType, diffItemType: DiffItemType, nextMiddleItem: TransformDiffItem?) -> (textPadding: NSDirectionalEdgeInsets, inBetweenSpacing: CGFloat?) {
        
        var top: CGFloat = 0
        var bottom: CGFloat = 0
        var inBetweenSpacing: CGFloat?
        if diffItemType == .moveSource || diffItemType == .moveDestination {
            top = 10
            if let middleItem = nextMiddleItem,
            middleItem.type == .moveSource || middleItem.type == .moveDestination {
                bottom = 10
                inBetweenSpacing = 10
            } else {
                bottom = 15
            }
        } else {
            if let middleItem = nextMiddleItem,
            middleItem.type == .moveSource || middleItem.type == .moveDestination {
                bottom = 10
            }
        }
        
        switch type {
        case .singleRevison:
            let leading: CGFloat = (diffItemType == .moveSource || diffItemType == .moveDestination) ? 10 : 0
            let trailing: CGFloat = (diffItemType == .moveSource || diffItemType == .moveDestination) ? 10 : 0
            return (NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing), inBetweenSpacing)
        case .compareRevision:
            return (NSDirectionalEdgeInsets(top: top, leading: 10, bottom: bottom, trailing: 10), inBetweenSpacing)
        }
    }
    
    private static func moveAttributedString(with text: String, diffItemType: DiffItemType, moveInfo: TransformMoveInfo, highlightedRanges: inout [DiffHighlightRange], traitCollection: UITraitCollection, theme: Theme) -> (moveAttributedString: NSAttributedString?, lengthOfPrefix: Int)? {
        
        guard !text.isEmpty,
            (diffItemType == .moveSource || diffItemType == .moveDestination) else {
            return nil
        }

        var modifiedText = text
        
        //additional move changes that are specific to the client
        if let moveIndex = moveInfo.groupedIndex {
            
            let moveIndexString = "  \(moveIndex + 1)  "
            let imageAttachment = NSTextAttachment()
            let imageName = moveInfo.linkDirection == .down ? "moveArrowDown" : "moveArrowUp"
            imageAttachment.image = UIImage(named: imageName)
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            switch diffItemType {
            case .moveSource:
                
                if let moveDistance = moveInfo.moveDistance {
                    var moveDistanceString: String
                    switch moveDistance {
                    case .section(let amount):
                        let moveDistanceSectionsFormat = WMFLocalizedString("diff-paragraph-moved-distance-section", value:"{{PLURAL:%1$d|%1$d section|%1$d sections}}", comment:"Diff view distance moved in sections when a paragraph has moved across sections - %1$@ is replaced with the number of sections a paragraph has moved across.")
                        moveDistanceString = String.localizedStringWithFormat(moveDistanceSectionsFormat, amount)
                    case .line(let amount):
                        let moveDistanceLinesFormat = WMFLocalizedString("diff-paragraph-moved-distance-line", value:"{{PLURAL:%1$d|%1$d line|%1$d lines}}", comment:"Diff view distance moved in line numbers when a paragraph has moved lines but remained in the same section - %1$@ is replaced with the number of lines a paragraph has moved across.")
                        moveDistanceString = String.localizedStringWithFormat(moveDistanceLinesFormat, amount)
                    }
                    
                    let paragraphMovedFormat = WMFLocalizedString("diff-paragraph-moved-format", value: "Paragraph moved %1$@ %2$@", comment: "Label in moved paragraph source location on diff view for indicating how far and what direction a pargraph has moved. %1$@ is replaced by the move direction (e.g. 'up' or 'down') and %2$@ is replaced by the move type and move distance (e.g. '2 lines', '4 sections')")
                    let upOrDownString: String
                    switch moveInfo.linkDirection {
                    case .down: upOrDownString = WMFLocalizedString("diff-paragraph-moved-direction-down", value: "down", comment: "Label in moved pararaph source location on diff view for indicating that a paragraph was moved down in the document.")
                    case .up: upOrDownString = WMFLocalizedString("diff-paragraph-moved-direction-up", value: "up", comment: "Label in moved pararaph source location on diff view for indicating that a paragraph was moved up in the document.")
                    }
                    
                    modifiedText = String.localizedStringWithFormat(paragraphMovedFormat, upOrDownString, moveDistanceString)
                } else {
                    modifiedText = WMFLocalizedString("diff-paragraph-moved", value:"Paragraph moved", comment:"Label in diff to indicate that a paragraph has been moved. This label is in the location of where the paragraph was moved from.")
                }
            case .moveDestination:
                
                let originalHighlightedRanges = highlightedRanges
                highlightedRanges.removeAll(keepingCapacity: true)
                for range in originalHighlightedRanges {
                    let amountToOffset = imageString.string.count + moveIndexString.count
                    let newRange = DiffHighlightRange(start: range.start + amountToOffset, length: range.length, type: range.type)
                    highlightedRanges.append(newRange)
                }
            default:
                assertionFailure("Cannot handle non-move diff item type here")
                return nil
            }
            
            let mutableAttributedString = NSMutableAttributedString(string: modifiedText)

            //insert move index number
            let indexAttributedString = NSAttributedString(string: moveIndexString)
            mutableAttributedString.insert(indexAttributedString, at: 0)
            
            //insert move arrow
            mutableAttributedString.insert(imageString, at:0)
            mutableAttributedString.addAttributes([NSAttributedString.Key.baselineOffset: -2], range: NSRange(location: 0, length: 1))
            
            return (moveAttributedString: mutableAttributedString.copy() as? NSAttributedString, lengthOfPrefix: indexAttributedString.length + imageString.length)
        }
        
        return nil
    }
    
    private static func updateParamsForAddDeleteLine(text: inout String, diffItemType: DiffItemType, highlightedRanges: inout [DiffHighlightRange]) {
        
        guard diffItemType == .addLine || diffItemType == .deleteLine else {
            return
        }
        
        if text.isEmpty {
            text = " "
        }
        
        var highlightRange: DiffHighlightRangeType? = nil
        switch diffItemType {
        case .addLine:
            highlightRange = .add
        case .deleteLine:
            highlightRange = .delete
        default:
            break
        }
        
        if let highlightRange = highlightRange {
            let newAddRange = DiffHighlightRange(start: 0, length: text.count, type: highlightRange)
            highlightedRanges.append(newAddRange)
        }
    }
    
    private static func calculateAttributedString(with text: String, highlightedRanges: [DiffHighlightRange], traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, moveInfo: TransformMoveInfo?, semanticContentAttribute: UISemanticContentAttribute) -> NSAttributedString? {
        
        var modifiedText = text
        var modifiedHighlightedRanges = highlightedRanges
        
        let regularFontStyle = DynamicTextStyle.subheadline
        let boldFontStyle = DynamicTextStyle.boldSubheadline

        let font = diffItemType == .moveSource || diffItemType == .moveDestination ? UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection) : UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection)

        var moveItemAttributedString: NSAttributedString?
        var lengthOfPrefix: Int?
        switch diffItemType {
        case .moveSource, .moveDestination:
            if let moveInfo = moveInfo {
                let moveResult = moveAttributedString(with: text, diffItemType: diffItemType, moveInfo: moveInfo, highlightedRanges: &modifiedHighlightedRanges, traitCollection: traitCollection, theme: theme)
                moveItemAttributedString = moveResult?.0
                lengthOfPrefix = moveResult?.1
            }
        case .addLine, .deleteLine:
            updateParamsForAddDeleteLine(text: &modifiedText, diffItemType: diffItemType, highlightedRanges: &modifiedHighlightedRanges)
        default:
            break
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        let lineSpacing: CGFloat = 4
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = font.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        
        if diffItemType == .moveSource {
            paragraphStyle.alignment = .center
        } else {
            switch semanticContentAttribute {
            case .forceRightToLeft:
                paragraphStyle.alignment = .right
            default:
                paragraphStyle.alignment = .left
            }
        }
        
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: theme.colors.primaryText,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle.copy()]
        
        let finalAttributedStringToHighlight: NSMutableAttributedString
        
        if let moveItemAttributedString = moveItemAttributedString,
            let lengthOfPrefix = lengthOfPrefix {
            let moveIndexAttributes = [NSAttributedString.Key.foregroundColor: theme.colors.diffCompareAccent]
            finalAttributedStringToHighlight = NSMutableAttributedString(attributedString: moveItemAttributedString)
            finalAttributedStringToHighlight.addAttributes(attributes, range: NSRange(location: 0, length: moveItemAttributedString.length))
            finalAttributedStringToHighlight.addAttributes(moveIndexAttributes, range: NSRange(location: 0, length: lengthOfPrefix))
        } else {
            finalAttributedStringToHighlight = NSMutableAttributedString(string: modifiedText, attributes: attributes)
        }
        
        for range in modifiedHighlightedRanges {

            let nsRange = NSRange(location: range.start, length: range.length)
            var highlightColor: UIColor?
            let textColor: UIColor?

            let isNotLightAndEmpty = theme != Theme.light && (diffItemType == .addLine || diffItemType == .deleteLine) &&
            text.isEmpty
            
            switch range.type {
            case .add:
                highlightColor = isNotLightAndEmpty ? theme.colors.diffTextAdd : theme.colors.diffHighlightAdd
                textColor = theme.colors.diffTextAdd

            case .delete:
                highlightColor = isNotLightAndEmpty ? theme.colors.diffTextDelete : theme.colors.diffHighlightDelete
                textColor = theme.colors.diffTextDelete
                let deletedAttributes: [NSAttributedString.Key: Any]  = [
                    NSAttributedString.Key.strikethroughStyle:NSUnderlineStyle.single.rawValue,
                    NSAttributedString.Key.strikethroughColor:theme.colors.diffStrikethroughColor as Any
                ]
                finalAttributedStringToHighlight.addAttributes(deletedAttributes, range: nsRange)
            }

            let font = UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection)
            finalAttributedStringToHighlight.addAttribute(NSAttributedString.Key.font, value: font, range: nsRange)
            
            if let highlightColor = highlightColor {
                finalAttributedStringToHighlight.addAttribute(NSAttributedString.Key.backgroundColor, value: highlightColor, range: nsRange)
            }
            
            if let textColor = textColor {
                finalAttributedStringToHighlight.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: nsRange)
            }
        }
        
        return finalAttributedStringToHighlight.copy() as? NSAttributedString
    }
}

extension DiffListChangeItemViewModel: Equatable {
    static func == (lhs: DiffListChangeItemViewModel, rhs: DiffListChangeItemViewModel) -> Bool {
        return lhs.highlightedRanges == rhs.highlightedRanges &&
            lhs.text == rhs.text
    }
}
