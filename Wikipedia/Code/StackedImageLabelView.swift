import WMFComponents

/// A vertically stacked image/label group that resembles `UITableView`'s swipe actions 
final class StackedImageLabelView: SetupView {

    // MARK: - Properties

    var increaseLabelTopPadding: Bool = false {
        didSet {
            labelTopConstraint.constant = increaseLabelTopPadding ? 8 : 2
            setNeedsLayout()
        }
    }

    private var imageDimension: CGFloat = 40
    private var labelTopConstraint: NSLayoutConstraint = NSLayoutConstraint()

    // MARK: - UI Elements

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Lifecycle

    override func setup() {
        addSubview(imageView)
        addSubview(label)

        labelTopConstraint = label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2)

        NSLayoutConstraint.activate([
            imageView.bottomAnchor.constraint(equalTo: centerYAnchor, constant: 3),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageDimension),
            imageView.heightAnchor.constraint(equalToConstant: imageDimension),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            labelTopConstraint,
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

}
