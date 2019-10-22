
import Foundation

final class DiffListChangeItemViewModel {
    let text: String
    let highlightedRanges: [DiffListItemHighlightRange]
    let type: DiffListChangeType
    let diffItemType: DiffItemType
    let textAlignment: NSTextAlignment
    let backgroundColor: UIColor
    private let groupedMoveIndexes: [String: Int]
    let moveInfo: DiffMoveInfo?

    var theme: Theme {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, groupedMoveIndexes: groupedMoveIndexes)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: moveInfo, groupedMoveIndexes: groupedMoveIndexes)
        }
    }
    
    private(set) var textAttributedString: NSAttributedString
    
    init(item: DiffItem, traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, groupedMoveIndexes: [String: Int]) {
        self.text = item.text
        self.traitCollection = traitCollection
        self.theme = theme
        self.type = type
        self.diffItemType = diffItemType
        self.groupedMoveIndexes = groupedMoveIndexes
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
        
        self.textAttributedString = DiffListChangeItemViewModel.calculateAttributedString(with: text, highlightedRanges: highlightedRanges, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItemType, moveInfo: item.moveInfo, groupedMoveIndexes: groupedMoveIndexes)
    }
    
    private static func calculateAttributedString(with text: String, highlightedRanges: [DiffListItemHighlightRange], traitCollection: UITraitCollection, theme: Theme, type: DiffListChangeType, diffItemType: DiffItemType, moveInfo: DiffMoveInfo?, groupedMoveIndexes: [String: Int]) -> NSAttributedString {
        
        //tonitodo: clean up this method 🤮
        var modifiedText = text
        var modifiedHighlightedRanges = highlightedRanges
        
        let regularFontStyle: DynamicTextStyle = type == .singleRevison ? .callout : .footnote
        let boldFontStyle: DynamicTextStyle = type == .singleRevison ? .boldCallout : .boldFootnote
        
        let font = diffItemType == .moveSource || diffItemType == .moveDestination ? UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection) : UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection)
        let attributes = [NSAttributedString.Key.font: font]
        
        //todo: failed progress on adding line spacing
//        let paragraphStyle = NSMutableParagraphStyle()
//        let lineSpacing: CGFloat = 4
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.lineHeightMultiple = font.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        
        
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
                modifiedText = WMFLocalizedString("diff-paragraph-moved", value:"Paragraph moved", comment:"Label in diff to indicate that a paragraph has been moved. This label is in the location of where the paragraph was moved from.")
            } else if diffItemType == .moveDestination {
                
                //todo: offset highlighted ranges since we added move index & arrow in the front
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
                let indexAttributes = [NSAttributedString.Key.font: UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection),
                                       NSAttributedString.Key.foregroundColor: theme.colors.warning]
                let indexAttributedString = NSAttributedString(string: moveIndexString, attributes: indexAttributes)
                maybeMutableAttributedString.insert(indexAttributedString, at: 0)
                
                //insert move arrow
                maybeMutableAttributedString.insert(imageString, at:0)
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
