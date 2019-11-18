
import UIKit

protocol DiffListContextCellDelegate: class {
    func didTapContextExpand(indexPath: IndexPath)
}

class DiffListContextCell: UICollectionViewCell {
    static let reuseIdentifier = "DiffListContextCell"
    
    @IBOutlet var innerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var innerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var innerTopConstraint: NSLayoutConstraint!
    @IBOutlet var containerStackView: UIStackView!
    @IBOutlet var contextItemStackView: UIStackView!
    
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var expandButton: UIButton!
    
    private var viewModel: DiffListContextViewModel?
    private var indexPath: IndexPath?
    
    weak var delegate: DiffListContextCellDelegate?
    
    func update(_ viewModel: DiffListContextViewModel, indexPath: IndexPath?) {
        
        if let indexPath = indexPath {
            self.indexPath = indexPath
        }
        
        innerLeadingConstraint.constant = viewModel.innerPadding.leading
        innerTrailingConstraint.constant = viewModel.innerPadding.trailing
        innerTopConstraint.constant = viewModel.innerPadding.top
        innerBottomConstraint.constant = viewModel.innerPadding.bottom
        
        containerStackView.spacing = DiffListContextViewModel.containerStackSpacing
        contextItemStackView.spacing = DiffListContextViewModel.contextItemStackSpacing
        
        headingLabel.font = viewModel.headingFont
        headingLabel.text = viewModel.heading
        
        if self.viewModel == nil {
            expandButton.setTitle(viewModel.expandButtonTitle, for: .normal)
        } else {
            expandButton.alpha = 0
            expandButton.setTitle(viewModel.expandButtonTitle, for: .normal)
            UIView.animate(withDuration: 0.2) {
                self.expandButton.alpha = 1
            }
        }
        
        expandButton.titleLabel?.font = viewModel.contextFont
        
        apply(theme: viewModel.theme)
        
        if needsNewContextViews(newViewModel: viewModel) {
            removeContextViews(from: contextItemStackView)
            addContextViews(to: contextItemStackView, newViewModel: viewModel)
        }
        
        updateContextViews(in: contextItemStackView, newViewModel: viewModel, theme: viewModel.theme)
        
        self.viewModel = viewModel
    }
    
    @IBAction func tappedExpandButton(_ sender: UIButton) {
        if let indexPath = indexPath {
            delegate?.didTapContextExpand(indexPath: indexPath)
        }
    }
}

private extension DiffListContextCell {
    
    func removeContextViews(from stackView: UIStackView) {
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }
    
    func addContextViews(to stackView: UIStackView, newViewModel: DiffListContextViewModel) {
        for item in newViewModel.items {
            
            if item != nil {
                
                //needs label
                let label = UILabel()
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.translatesAutoresizingMaskIntoConstraints = false
                
                let view = UIView(frame: .zero)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                
                let top = label.topAnchor.constraint(equalTo: view.topAnchor, constant: DiffListContextViewModel.contextItemTextPadding.top)
                let bottom = view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: DiffListContextViewModel.contextItemTextPadding.bottom)
                let leading = label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DiffListContextViewModel.contextItemTextPadding.leading)
                let trailing = view.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: DiffListContextViewModel.contextItemTextPadding.trailing)
                
                view.addConstraints([top, bottom, leading, trailing])
                
                stackView.addArrangedSubview(view)
            } else {
                let view = UIView(frame: .zero)
                
                view.translatesAutoresizingMaskIntoConstraints = false
                let heightConstraint = view.heightAnchor.constraint(equalToConstant: newViewModel.emptyContextLineHeight)
                view.addConstraint(heightConstraint)
                
                stackView.addArrangedSubview(view)
            }
            
            
        }
    }
    
    func updateContextViews(in stackView: UIStackView, newViewModel: DiffListContextViewModel, theme: Theme) {
        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            
            subview.backgroundColor = theme.colors.diffContextItemBackground
            subview.borderColor = theme.colors.diffContextItemBorder
            subview.borderWidth = 1
            subview.layer.cornerRadius = 5
            
            if let item = newViewModel.items[safeIndex: index] as? DiffListContextItemViewModel,
            let label = subview.subviews.first as? UILabel {
                label.attributedText = item.textAttributedString
            }
        }
    }
    
    func needsNewContextViews(newViewModel: DiffListContextViewModel) -> Bool {
        guard let viewModel = viewModel else {
            return true
        }
        
        if viewModel.items != newViewModel.items {
            return true
        }
        
        return false
    }
}

extension DiffListContextCell: Themeable {
    func apply(theme: Theme) {
        headingLabel.textColor = theme.colors.secondaryText
        expandButton.tintColor = theme.colors.link
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        
        if let viewModel = viewModel {
            updateContextViews(in: contextItemStackView, newViewModel: viewModel, theme: theme)
        }
    }
}
