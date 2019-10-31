
import Foundation

final class DiffListChangeItemViewModel {
    let text: String
    let highlightedRanges: [DiffListItemHighlightRange]
    let type: DiffListChangeType
    let diffItemType: DiffItemType
    let textAlignment: NSTextAlignment
    let backgroundColor: UIColor
    private let groupedMoveIndexes: [String: Int]
    private let moveDistances: [String: MoveDistance]
    let moveInfo: DiffMoveInfo?
    private(set) var textPadding: NSDirectionalEdgeInsets

    var theme: Theme {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, groupedMoveIndexes: groupedMoveIndexes, moveDistances: moveDistances)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, groupedMoveIndexes: groupedMoveIndexes, moveDistances: moveDistances)
        }
    }
    
    private(set) var textAttributedString: NSAttributedString
    
    init(item: DiffItem, traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, groupedMoveIndexes: [String: Int], moveDistances: [String: MoveDistance], nextMiddleItem: DiffItem?) {
        self.text = item.text
        self.traitCollection = traitCollection
        self.theme = theme
        self.type = type
        self.diffItemType = diffItemType
        self.groupedMoveIndexes = groupedMoveIndexes
        self.moveDistances = moveDistances
        self.moveInfo = item.moveInfo
        
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

        textAlignment = diffItemType == .moveSource ? .center : .natural
        backgroundColor = (diffItemType == .moveSource || diffItemType == .moveDestination) ? theme.colors.cardBorder : theme.colors.paperBackground
        
        self.textPadding = DiffListChangeItemViewModel.calculateTextPadding(type: type, diffItemType: diffItemType, nextMiddleItem: nextMiddleItem)
        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: item.moveInfo, groupedMoveIndexes: groupedMoveIndexes, moveDistances: moveDistances)
    }
    
    private static func calculateTextPadding(type: DiffListChangeType, diffItemType: DiffItemType, nextMiddleItem: DiffItem?) -> NSDirectionalEdgeInsets {
        
        var top: CGFloat = 0
        var bottom: CGFloat = 0
        if diffItemType == .moveSource || diffItemType == .moveDestination {
            top = 10
            if let middleItem = nextMiddleItem,
            middleItem.type == .moveSource || middleItem.type == .moveDestination {
                bottom = 0
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
            return NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: top, leading: 10, bottom: bottom, trailing: 10)
        }
        
    }
    
    private static func calculateAttributedString(with text: String, highlightedRanges: [DiffListItemHighlightRange], traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, moveInfo: DiffMoveInfo?, groupedMoveIndexes: [String: Int], moveDistances: [String: MoveDistance]) -> NSAttributedString {
        
        //tonitodo: clean up this method 🤮
        var modifiedText = text
        var modifiedHighlightedRanges = highlightedRanges
        
        let regularFontStyle: DynamicTextStyle = .footnote
        let boldFontStyle: DynamicTextStyle = .boldFootnote
        
        let font = diffItemType == .moveSource || diffItemType == .moveDestination ? UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection) : UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection)
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        let lineSpacing: CGFloat = 4
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = font.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle.copy()]
        
        
        //additional move changes that are specific to the client
        var maybeMutableAttributedString: NSMutableAttributedString? = nil
        if let moveInfo = moveInfo,
            let moveIndex = groupedMoveIndexes[moveInfo.id] {
            
            let moveIndexString = "  \(moveIndex + 1)  "
            let imageAttachment = NSTextAttachment()
            let imageName = moveInfo.linkDirection == .down ? "moveArrowDown" : "moveArrowUp"
            imageAttachment.image = UIImage(named: imageName)
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            if diffItemType == .moveSource {
                
                if let moveDistance = moveDistances[moveInfo.id] {
                    
                    var moveDistanceString: String
                    switch moveDistance {
                    case .section(let sectionNumberAmount, _):
                        let moveDistanceSectionsFormat = WMFLocalizedString("diff-paragraph-moved-distance-section", value:"{{PLURAL:%1$d|%1$d section|%1$d sections}}", comment:"Diff view distance moved in sections when a paragraph has moved across sections - %1$@ is replaced with the number of sections a paragraph has moved across.")
                        moveDistanceString = String.localizedStringWithFormat(moveDistanceSectionsFormat, sectionNumberAmount)
                    case .line (let lineNumberAmount):
                        let moveDistanceLinesFormat = WMFLocalizedString("diff-paragraph-moved-distance-line", value:"{{PLURAL:%1$d|%1$d line|%1$d lines}}", comment:"Diff view distance moved in line numbers when a paragraph has moved lines but remained in the same section - %1$@ is replaced with the number of lines a paragraph has moved across.")
                        moveDistanceString = String.localizedStringWithFormat(moveDistanceLinesFormat, lineNumberAmount)
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
               
                paragraphStyle.alignment = .center
            } else if diffItemType == .moveDestination {
                
                let originalHighlightedRanges = modifiedHighlightedRanges
                modifiedHighlightedRanges.removeAll(keepingCapacity: true)
                for highlightedRange in originalHighlightedRanges {
                    let amountToOffset = imageString.string.count + moveIndexString.count
                    let newRange = DiffListItemHighlightRange(start: highlightedRange.start + amountToOffset, length: highlightedRange.length, type: highlightedRange.type)
                    modifiedHighlightedRanges.append(newRange)
                }
            }
            
            let attributedString = NSAttributedString(string: modifiedText, attributes: attributes)
            maybeMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            if let maybeMutableAttributedString = maybeMutableAttributedString {
                
                //insert move index number
                let indexAttributes = [NSAttributedString.Key.font: UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection),
                                       NSAttributedString.Key.foregroundColor: theme.colors.warning]
                let indexAttributedString = NSAttributedString(string: moveIndexString, attributes: indexAttributes)
                maybeMutableAttributedString.insert(indexAttributedString, at: 0)
                
                //insert move arrow
                maybeMutableAttributedString.insert(imageString, at:0)
                maybeMutableAttributedString.addAttributes([NSAttributedString.Key.baselineOffset: -2], range: NSRange(location: 0, length: 1))
                
                //line spacing moved paragraphs
                maybeMutableAttributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle.copy()], range: NSRange(location: 0, length: maybeMutableAttributedString.string.count))
            }
        }
        
        //additional highlighting implementations that are specific to the client
        //for added and deleted lines, add a space if empty and highlight string appropriately
        if diffItemType == .addLine || diffItemType == .deleteLine {
            if text.isEmpty {
                modifiedText = " "
            }
            
            var highlightRange: DiffListItemHighlightRange.HighlightType? = nil
            switch diffItemType {
            case .addLine:
                highlightRange = .added
            case .deleteLine:
                highlightRange = .deleted
            default:
                break
            }
            
            if let highlightRange = highlightRange {
                let newAddRange = DiffListItemHighlightRange(start: 0, length: modifiedText.count, type: highlightRange)
                modifiedHighlightedRanges.append(newAddRange)
            }
        }
        
        let attributedString = NSAttributedString(string: modifiedText, attributes: attributes)
        let mutableAttributedString: NSMutableAttributedString = maybeMutableAttributedString != nil ? maybeMutableAttributedString! : NSMutableAttributedString(attributedString: attributedString)
        
        for range in modifiedHighlightedRanges {

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

            let font = UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection)
            mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: highlightColor, range: nsRange)
            mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: font, range: nsRange)
        }
        
        return mutableAttributedString
    }
}

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

fileprivate extension UIFont
{
    func lineSpacingToMatch(lineHeightMultiple: CGFloat) -> CGFloat {
        return self.lineHeight * (lineHeightMultiple - 1)
    }

    func lineHeightMultipleToMatch(lineSpacing: CGFloat) -> CGFloat {
        return 1 + lineSpacing / self.lineHeight
    }
}
