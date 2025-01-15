import UIKit
import CocoaLumberjackSwift

final class DiffHeaderView: UICollectionReusableView, Themeable {
    lazy var contentView: DiffHeaderContentView = {
        let view = DiffHeaderContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(contentView)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: contentView.topAnchor),
            leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with vm: DiffHeaderViewModel, tappedHeaderTitleAction: (() -> Void)?, theme: Theme) {
        contentView.configure(with: vm, tappedHeaderTitleAction: tappedHeaderTitleAction, theme: theme)
    }
    
    func apply(theme: Theme) {
        contentView.apply(theme: theme)
    }
}

final class DiffHeaderContentView: UIView {

    var viewModel: DiffHeaderViewModel?

    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top

        return stackView
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.masksToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4
        return imageView
    }()


    lazy var headerTitleView: DiffHeaderTitleView = {
        let titleView = DiffHeaderTitleView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        return titleView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(horizontalStackView)
        horizontalStackView.addArrangedSubview(headerTitleView)

        imageView.isAccessibilityElement = false

            NSLayoutConstraint.activate([
                horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
                horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
                horizontalStackView.leadingAnchor.constraint(equalTo:  layoutMarginsGuide.leadingAnchor, constant: 10),
                horizontalStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -10)

            ])
        horizontalStackView.spacing = 16
        horizontalStackView.addArrangedSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.widthAnchor.constraint(equalToConstant: 80)
        ])

    }

    func configure(with vm: DiffHeaderViewModel, tappedHeaderTitleAction: (() -> Void)?, theme: Theme) {
        self.viewModel = vm
        if let viewModel {
            updateTitleView(with: viewModel.title, tappedHeaderTitleAction: tappedHeaderTitleAction)
            updateImageView(with: viewModel)
        }
        
        apply(theme: theme)
    }

    func updateImageView(with new: DiffHeaderViewModel) {
        self.viewModel = new

        if let leadImageURL = viewModel?.imageURL {
            imageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
                DDLogWarn("Failure loading diff header image: \(error)")
            }, success: { [weak self] in
                self?.imageView.isHidden = false
            })
        } else {
            imageView.isHidden = true
        }
    }

    func updateTitleView(with viewModel: DiffHeaderTitleViewModel, tappedHeaderTitleAction: (() -> Void)?) {
        headerTitleView.update(viewModel, tappedHeaderTitleAction: tappedHeaderTitleAction)
    }
}

extension DiffHeaderContentView: Themeable {
    func apply(theme: Theme) {
        headerTitleView.apply(theme: theme)
    }
}
