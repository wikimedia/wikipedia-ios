import Foundation

@objc (WMFLicenseView)
class LicenseView: UIStackView {
    @objc public var licenseCodes: [String] = [] {
        didSet {
            axis = .horizontal
            alignment = .center
            spacing = 5
            for view in arrangedSubviews {
                view.removeFromSuperview()
            }
            for license in licenseCodes {
                guard let image = UIImage(named: "license-" + license) else {
                    continue
                }
                let imageView = UIImageView(image: image)
                imageView.contentMode = .center
                imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
                addArrangedSubview(imageView)
            }
        }
    }
}
