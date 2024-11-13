import UIKit
import CocoaLumberjackSwift

final class DiffHeaderView: SetupView {

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
        titleView.masksToBounds = true
        return titleView
    }()

    override func setup() {
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

    func configure(with vm: DiffHeaderViewModel, titleViewTapDelegate: DiffHeaderTitleViewTapDelegate? = nil) {
        self.viewModel = vm
        if let viewModel {
            updateTitleView(with: viewModel.title, titleViewTapDelegate: titleViewTapDelegate)
            updateImageView(with: viewModel)
        }
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

    func updateTitleView(with viewModel: DiffHeaderTitleViewModel, titleViewTapDelegate: DiffHeaderTitleViewTapDelegate? = nil) {
        headerTitleView.update(viewModel, titleViewTapDelegate: titleViewTapDelegate)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }

        let headerTitleViewConvertedPoint = convert(point, to: headerTitleView)
        if headerTitleView.point(inside: headerTitleViewConvertedPoint, with: event) {
            return true
        }

        return false
    }

}

extension DiffHeaderView: Themeable {
    func apply(theme: Theme) {
        headerTitleView.apply(theme: theme)
    }
}
