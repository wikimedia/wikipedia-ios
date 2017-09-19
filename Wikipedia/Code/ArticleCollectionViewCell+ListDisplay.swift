import Foundation

extension ArticleRightAlignedImageCollectionViewCell {
    public func configureForCompactList(at indexPath: IndexPath) {
        topSeparator.isHidden = indexPath.item > 0
        bottomSeparator.isHidden = false
        margins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        titleTextStyle = .subheadline
        descriptionTextStyle = .footnote
        updateFonts(with: traitCollection)
        imageViewDimension = 40
        isSaveButtonHidden = true
    }
    
    @objc public var imageURL: URL? {
        set {
            guard let newURL = newValue else {
                isImageViewHidden = true
                imageView.wmf_reset()
                return
            }
            isImageViewHidden = false
            imageView.wmf_setImage(with: newURL, detectFaces: true, onGPU: true, failure: WMFIgnoreErrorHandler, success: WMFIgnoreSuccessHandler)
        }
        get {
            return imageView.wmf_imageURLToFetch
        }
    }
}
