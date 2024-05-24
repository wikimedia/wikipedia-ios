import UIKit

protocol DiffListChangeCellDelegate: AnyObject {
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
    @IBOutlet weak var divView: UIView!
    
    private(set) var viewModel: DiffListChangeViewModel?
    private var textLabels: [UILabel] = []
    private var shadedBackgroundViews: [UIView] = []
    private var spacerViews: [UIView] = []
    
    weak var delegate: DiffListChangeCellDelegate?
    
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
            reset()
            addTextLabels(to: textStackView, newViewModel: viewModel)
        }
        
        updateTextLabels(in: textStackView, newViewModel: viewModel)

        self.viewModel = viewModel

        apply(theme: viewModel.theme)
    }
    
    func arrangedSubview(at index: Int) -> UIView? {
        
        guard textStackView.arrangedSubviews.count > index else {
            return nil
        }
        
        return textStackView.arrangedSubviews[index]
    }
    
    func yLocationOfItem(index: Int, convertView: UIView) -> CGFloat? {
        
        guard let item = textStackView.arrangedSubviews[safeIndex: index] else {
            return nil
        }
        
        return textStackView.convert(item.frame, to: convertView).minY
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
    func reset() {
        for subview in textStackView.arrangedSubviews {
            textStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        textLabels.removeAll()
        shadedBackgroundViews.removeAll()
        spacerViews.removeAll()
    }
    
    func addTextLabels(to textStackView: UIStackView, newViewModel: DiffListChangeViewModel) {
        for (index, item) in newViewModel.items.enumerated() {
            let label = UILabel()
            textLabels.append(label)
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = item.textAlignment
            label.isUserInteractionEnabled = true
            label.tag = index
            label.translatesAutoresizingMaskIntoConstraints = false

            if item.diffItemType.isMoveBased {
                if label.gestureRecognizers == nil {
                    addTapGestureRecognizer(to: label)
                } else if let gestureRecognizers = label.gestureRecognizers, gestureRecognizers.isEmpty {
                    addTapGestureRecognizer(to: label)
                }
            }

            // add surrounding view
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            
            // shaded background view
            if item.hasShadedBackgroundView {
                let shadedBackgroundView = UIView(frame: .zero)
                shadedBackgroundViews.append(shadedBackgroundView)
                shadedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
                
                shadedBackgroundView.addSubview(label)
                
                view.addSubview(shadedBackgroundView)
                
                let textTop = label.topAnchor.constraint(equalTo: shadedBackgroundView.topAnchor, constant: item.textPadding.top)
                let textBottom = shadedBackgroundView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: item.textPadding.bottom)
                let textLeading = label.leadingAnchor.constraint(equalTo: shadedBackgroundView.leadingAnchor, constant: item.textPadding.leading)
                let textTrailing = shadedBackgroundView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: item.textPadding.trailing)
                shadedBackgroundView.addConstraints([textTop, textBottom, textLeading, textTrailing])
                
                let top = shadedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
                let leading = shadedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0)
                let trailing = view.trailingAnchor.constraint(equalTo: shadedBackgroundView.trailingAnchor, constant: 0)
                view.addConstraints([top, leading, trailing])
                
                if let inBetweenSpacing = item.inBetweenSpacing {
                    let spacerView = UIView(frame: .zero)
                    spacerViews.append(spacerView)
                    spacerView.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(spacerView)
                    
                    let spacerTop = spacerView.topAnchor.constraint(equalTo: shadedBackgroundView.bottomAnchor, constant: 0)
                    let spacerBottom = view.bottomAnchor.constraint(equalTo: spacerView.bottomAnchor, constant: 0)
                    let spacerLeading = spacerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0)
                    let spacerTrailing = view.trailingAnchor.constraint(equalTo: spacerView.trailingAnchor, constant: 0)
                    let spacerHeight = spacerView.heightAnchor.constraint(equalToConstant: inBetweenSpacing)
                    view.addConstraints([spacerTop, spacerBottom, spacerLeading, spacerTrailing, spacerHeight])
                } else {
                    let bottom = view.bottomAnchor.constraint(equalTo: shadedBackgroundView.bottomAnchor, constant: 0)
                    view.addConstraints([bottom])
                }
            } else {
                view.addSubview(label)
                let textTop = label.topAnchor.constraint(equalTo: view.topAnchor, constant: item.textPadding.top)
                let textBottom = view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: item.textPadding.bottom)
                let textLeading = label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: item.textPadding.leading)
                let textTrailing = view.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: item.textPadding.trailing)
                view.addConstraints([textTop, textBottom, textLeading, textTrailing])
            }
            
            
            textStackView.addArrangedSubview(view)
        }
    }

    private func addTapGestureRecognizer(to label: UILabel) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedLabelWithSender(_:)))
        label.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func updateTextLabels(in textStackView: UIStackView, newViewModel: DiffListChangeViewModel) {
        
        for (index, label) in textLabels.enumerated() {
            if let item = newViewModel.items[safeIndex: index] {
                label.attributedText = item.textAttributedString
                label.accessibilityLabel = item.accessibilityLabelText
                label.accessibilityTextualContext = .sourceCode
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
        divView.backgroundColor = theme.colors.baseBackground

        if let viewModel = viewModel {
            innerView.clipsToBounds = viewModel.innerViewClipsToBounds
            headingLabel.attributedText = viewModel.headingAttributedString
        }
        
        for shadedBackgroundView in shadedBackgroundViews {
            shadedBackgroundView.backgroundColor = theme.colors.diffMoveParagraphBackground
        }
        
        for spacerView in spacerViews {
            spacerView.backgroundColor = theme.colors.paperBackground
        }
        
        for subview in textStackView.arrangedSubviews {
            subview.backgroundColor = theme.colors.paperBackground
        }
    }
}
