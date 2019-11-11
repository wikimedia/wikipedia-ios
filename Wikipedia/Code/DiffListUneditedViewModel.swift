
import Foundation

final class DiffListUneditedViewModel: DiffListGroupViewModel {
    private(set) var height: CGFloat = 0
    
    private var _width: CGFloat
    var width: CGFloat {
        get {
            return _width
        }
        set {
            _width = newValue
            height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
        }
    }
    
    var traitCollection: UITraitCollection {
        didSet {
            font = DiffListUneditedViewModel.calculateTextLabelFont(traitCollection: traitCollection)
        }
    }
    
    let text: String
    var theme: Theme
    private(set) var font: UIFont
    private(set) var innerPadding: NSDirectionalEdgeInsets
    
    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing
    }
    
    init(numberOfUneditedLines: Int, theme: Theme, width: CGFloat, traitCollection: UITraitCollection) {
        self.theme = theme
        self._width = width
        self.traitCollection = traitCollection
        self.theme = theme
        self.innerPadding = DiffListUneditedViewModel.calculateInnerPadding(traitCollection: traitCollection)
        self.font = DiffListUneditedViewModel.calculateTextLabelFont(traitCollection: traitCollection)
        
        self.text = String.localizedStringWithFormat(WMFLocalizedString("diff-unedited-lines-format", value:"{{PLURAL:%1$d|%1$d line unedited|%1$d lines unedited}}", comment:"Label in diff to indicate how many lines are not displayed because they were not changed. %1$d is replaced by the number of unedited lines."), numberOfUneditedLines)
        self.height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
    }
    
    private static func calculateInnerPadding(traitCollection: UITraitCollection) -> NSDirectionalEdgeInsets {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
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
    
    func updateSize(width: CGFloat, traitCollection: UITraitCollection) {
        _width = width
        self.traitCollection = traitCollection
        
        height = DiffListUneditedViewModel.calculateHeight(text: text, availableWidth: availableWidth, innerPadding: innerPadding, font: font)
    }
}
