import Foundation
import UIKit
import WMFData

@objc final public class WMFAltTextExperimentModalSheetViewModel: NSObject {
    public var altTextViewModel: WMFAltTextExperimentViewModel
    public var localizedStrings: LocalizedStrings
    public var uiImage: UIImage?

    public struct LocalizedStrings {
        public var title: String
        public var buttonTitle: String
        public var textViewPlaceholder: String

        public init(title: String, buttonTitle: String, textViewPlaceholder: String) {
            self.title = title
            self.buttonTitle = buttonTitle
            self.textViewPlaceholder = textViewPlaceholder
        }
    }

    public init(altTextViewModel: WMFAltTextExperimentViewModel, localizedStrings: LocalizedStrings) {
        self.altTextViewModel = altTextViewModel
        self.localizedStrings = localizedStrings
    }
    
    public func populateUIImage(for imageURL: URL, completion: @escaping (Error?) -> Void) {
        
        let imageDataController = WMFImageDataController()
        imageDataController.fetchImageData(url: imageURL) { [weak self] result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    let image = UIImage(data: data)
                    self?.uiImage = image
                    completion(nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    public var fileNameForDisplay: String {
        return altTextViewModel.filename.removingNamespace().underscoresToSpaces
    }

}

private extension String {
    func removingNamespace() -> String {
        guard let firstColon = self.firstIndex(of: ":") else {
            return self
        }
        
        guard firstColon != self.endIndex else {
            return self
        }
        
        let nextIndex = self.index(after: firstColon)
        
        return String(self.suffix(from: nextIndex))
    }
}
