import UIKit
import AVFoundation

final class InsertMediaSelectedImageView: SetupView {
    private let imageView = AlignedImageView()
    private let imageInfoView = InsertMediaImageInfoView.wmf_viewFromClassNib()!
    private let imageInfoContainerView = UIView()
    private var imageInfoContainerViewBottomConstraint: NSLayoutConstraint?

    public var moreInformationAction: ((URL) -> Void)?

    var image: UIImage? {
        return imageView.image
    }

    var searchResult: InsertMediaSearchResult?

    override func setup() {
        super.setup()
        imageView.alignment = [.top]
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        wmf_addSubviewWithConstraintsToEdges(imageView)

        imageInfoContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageInfoContainerView)
        imageInfoContainerView.alpha = 0.8
        let leadingConstraint = imageInfoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailingConstraint = imageInfoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottomConstraint = imageInfoContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let heightConstraint = imageInfoContainerView.heightAnchor.constraint(lessThanOrEqualTo: imageView.heightAnchor, multiplier: 0.5)
        imageInfoContainerViewBottomConstraint = bottomConstraint
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            heightConstraint
        ])

        imageInfoView.translatesAutoresizingMaskIntoConstraints = false
        imageInfoContainerView.backgroundColor = UIColor.white
        imageInfoContainerView.wmf_addSubviewWithConstraintsToEdges(imageInfoView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.adjustImageInfoContainerViewBottomConstraint()
    }

    private func adjustImageInfoContainerViewBottomConstraint() {
        guard
            imageView.alignment == .top,
            let image = image
        else {
            return
        }
        let imageHeight = AVMakeRect(aspectRatio: image.size, insideRect: imageView.frame).height
        let spaceBetweenImageAndInfoView = frame.size.height - imageHeight - imageInfoContainerView.frame.height
        if spaceBetweenImageAndInfoView >= imageInfoContainerView.frame.height || imageInfoContainerView.frame.height - spaceBetweenImageAndInfoView <= spaceBetweenImageAndInfoView {
            imageInfoContainerViewBottomConstraint?.constant = 0 - spaceBetweenImageAndInfoView * 0.5
        } else {
            imageInfoContainerViewBottomConstraint?.constant = 0
        }
    }

    public func configure(with imageURL: URL, searchResult: InsertMediaSearchResult, theme: Theme, completion: @escaping (Error?) -> Void) {
        imageView.image = nil
        imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
            completion(error)
        }) {
            self.searchResult = searchResult
            self.imageView.backgroundColor = self.backgroundColor
            self.imageInfoView.moreInformationAction = self.moreInformationAction
            self.imageInfoView.configure(with: searchResult, showImageDescription: false, showLicenseName: true, showMoreInformationButton: true, theme: theme)
            self.adjustImageInfoContainerViewBottomConstraint()
            completion(nil)
        }
    }
}

extension InsertMediaSelectedImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.baseBackground
        imageInfoContainerView.backgroundColor = backgroundColor
        imageView.backgroundColor = backgroundColor
    }
}
