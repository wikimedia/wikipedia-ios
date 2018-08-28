import Foundation

extension ArticleCollectionViewCell {
    @objc open func configureForCompactList(at index: Int) {
        layoutMargins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        imageViewDimension = 40
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

extension ArticleRightAlignedImageCollectionViewCell {
    @objc open func configureSeparators(for index: Int) {
        topSeparator.isHidden = index > 0
        bottomSeparator.isHidden = false
    }

    open override func configureForCompactList(at index: Int) {
        super.configureForCompactList(at: index)
        configureSeparators(for: index)
    }
}
