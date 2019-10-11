
import UIKit

class DiffListUneditedCell: UICollectionViewCell {
    
    static let reuseIdentifier = "DiffListUneditedCell"
    
    @IBOutlet var innerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var innerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerTopConstraint: NSLayoutConstraint!
    @IBOutlet var innerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var divView: UIView!
    @IBOutlet var textBackgroundView: UIView!
    
    func update(_ viewModel: DiffListUneditedViewModel) {
        innerLeadingConstraint.constant = viewModel.innerPadding.leading
        innerTrailingConstraint.constant = viewModel.innerPadding.trailing
        innerTopConstraint.constant = viewModel.innerPadding.top
        innerBottomConstraint.constant = viewModel.innerPadding.bottom
        
        textLabel.font = viewModel.font
        textLabel.text = viewModel.text
        textLabel.textColor = viewModel.theme.colors.secondaryText
        
        backgroundColor = viewModel.theme.colors.paperBackground
        textBackgroundView.backgroundColor = viewModel.theme.colors.paperBackground
        divView.backgroundColor = viewModel.theme.colors.border
    }
}
