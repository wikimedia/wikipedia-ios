import UIKit

class DiffListUneditedCell: UICollectionViewCell {
    
    static let reuseIdentifier = "DiffListUneditedCell"
    
    @IBOutlet var innerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var innerTopConstraint: NSLayoutConstraint!
    @IBOutlet var innerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var divView: UIView!
    
    func update(_ viewModel: DiffListUneditedViewModel) {
        innerLeadingConstraint.constant = viewModel.innerPadding.leading
        innerTopConstraint.constant = viewModel.innerPadding.top
        innerBottomConstraint.constant = viewModel.innerPadding.bottom
        
        textLabel.font = viewModel.font
        textLabel.text = viewModel.text.localizedCapitalized
        textLabel.accessibilityTextualContext = .sourceCode

        apply(theme: viewModel.theme)
    }
}

extension DiffListUneditedCell: Themeable {
    func apply(theme: Theme) {
        textLabel.textColor = theme.colors.secondaryText
        backgroundColor = theme.colors.paperBackground
        divView.backgroundColor = theme.colors.baseBackground
    }
}
