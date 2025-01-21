import Foundation
import WMFComponents

@objc extension WMFImageGalleryViewController {
    @objc static func closeButtonImage() -> UIImage? {
        return WMFSFSymbolIcon.for(symbol: .close)
    }
}
