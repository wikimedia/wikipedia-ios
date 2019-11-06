
import UIKit

protocol DiffListChangeCellDelegate: class {
    func didTapItem(item: DiffListChangeItemViewModel)
}

class DiffListChangeCell: UICollectionViewCell {
    static let reuseIdentifier = "DiffListChangeCell"
    
    @IBOutlet var textLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var textTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var textTopConstraint: NSLayoutConstraint!
    @IBOutlet var textBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var innerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var innerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var innerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var innerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var headingLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var headingTopConstraint: NSLayoutConstraint!
    @IBOutlet var headingBottomConstraint: NSLayoutConstraint!
    @IBOutlet var headingTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var headingContainerView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var textStackView: UIStackView!
    @IBOutlet var innerView: UIView!
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    private(set) var viewModel: DiffListChangeViewModel?
    
    weak var delegate: DiffListChangeCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedLabelWithSender(_:)))
    }
    
    func update(_ viewModel: DiffListChangeViewModel) {
        
        textLeadingConstraint.constant = viewModel.stackViewPadding.leading
        textTrailingConstraint.constant = viewModel.stackViewPadding.trailing
        textTopConstraint.constant = viewModel.stackViewPadding.top
        textBottomConstraint.constant = viewModel.stackViewPadding.bottom
        
        innerLeadingConstraint.constant = viewModel.innerPadding.leading
        innerTrailingConstraint.constant = viewModel.innerPadding.trailing
        innerTopConstraint.constant = viewModel.innerPadding.top
        innerBottomConstraint.constant = viewModel.innerPadding.bottom
        
        headingLeadingConstraint.constant = viewModel.headingPadding.leading
        headingTrailingConstraint.constant = viewModel.headingPadding.trailing
        headingBottomConstraint.constant = viewModel.headingPadding.bottom
        headingTopConstraint.constant = viewModel.headingPadding.top

        if needsNewTextLabels(newViewModel: viewModel) {
            removeTextLabels(from: textStackView)
            addTextLabels(to: textStackView, newViewModel: viewModel)
        }
        
        updateTextLabels(in: textStackView, newViewModel: viewModel)

        innerView.borderWidth = 1
        
        self.viewModel = viewModel
        
        apply(theme: viewModel.theme)
    }
    
    @objc func tappedLabelWithSender(_ sender: UITapGestureRecognizer) {
        if let sender = sender.view as? UILabel,
            let item = viewModel?.items[safeIndex: sender.tag],
            item.diffItemType == .moveSource || item.diffItemType == .moveDestination {
            
            delegate?.didTapItem(item: item)
        }
    }
}

private extension DiffListChangeCell {
    func removeTextLabels(from textStackView: UIStackView) {
        for subview in textStackView.arrangedSubviews {
            textStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }
    
    func addTextLabels(to textStackView: UIStackView, newViewModel: DiffListChangeViewModel) {
        for (index, item) in newViewModel.items.enumerated() {
            let label = UILabel()
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = item.textAlignment
            label.isUserInteractionEnabled = true
            label.tag = index
            label.translatesAutoresizingMaskIntoConstraints = false
            
            if let tapGestureRecognizer = tapGestureRecognizer {
                label.addGestureRecognizer(tapGestureRecognizer)
            }
            
            //add surrounding view
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            view.backgroundColor = item.backgroundColor
            
            let top = label.topAnchor.constraint(equalTo: view.topAnchor, constant: item.textPadding.top)
            let bottom = view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: item.textPadding.bottom)
            let leading = label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: item.textPadding.leading)
            let trailing = view.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: item.textPadding.trailing)
            view.addConstraints([top, bottom, leading, trailing])
            
            textStackView.addArrangedSubview(view)
        }
    }
    
    func updateTextLabels(in textStackView: UIStackView, newViewModel: DiffListChangeViewModel) {
        for (index, subview) in textStackView.arrangedSubviews.enumerated() {
            if let label = subview.subviews.first as? UILabel,
                let item = newViewModel.items[safeIndex: index] {
                label.attributedText = item.textAttributedString
            }
        }
    }
    
    func needsNewTextLabels(newViewModel: DiffListChangeViewModel) -> Bool {
        guard let viewModel = viewModel else {
            return true
        }
        
        if viewModel.items != newViewModel.items {
            return true
        }
        
        return false
    }
}

extension DiffListChangeCell: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        
        if let viewModel = viewModel {
            innerView.borderColor = viewModel.borderColor
            innerView.layer.cornerRadius = viewModel.innerViewClipsToBounds ? 7 : 0
            innerView.clipsToBounds = viewModel.innerViewClipsToBounds
            
            headingContainerView.backgroundColor = viewModel.borderColor
            headingLabel.attributedText = viewModel.headingAttributedString
            
            guard viewModel.items.count == textStackView.arrangedSubviews.count else {
                assertionFailure("textStackView subviews should equal the number of items in DiffChangeViewModel.")
                return
            }
            
            let zipped = zip(viewModel.items, textStackView.arrangedSubviews)
            
            for zippedItem in zipped {
                
                zippedItem.1.backgroundColor = zippedItem.0.backgroundColor
            }
        }
        
    }
}
