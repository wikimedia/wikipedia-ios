import UIKit

public class WMFEmptyViewModel: ObservableObject {

    public struct LocalizedStrings {
        public var title: String
        public var subtitle: String
        public var titleFilter: String?
        public var buttonTitle: String?
        public var attributedFilterString: ((Int) -> AttributedString)?

        public init(title: String, subtitle: String, titleFilter: String?, buttonTitle: String?, attributedFilterString: ((Int) -> AttributedString)?) {
            self.title = title
            self.subtitle = subtitle
            self.titleFilter = titleFilter
            self.buttonTitle = buttonTitle
            self.attributedFilterString = attributedFilterString
        }
    }

    var localizedStrings: LocalizedStrings
    var image: UIImage?
    var imageColor: UIColor?
    @Published var numberOfFilters: Int?

    /// The size to draw `image` at.
    ///
    /// Defaults to the illustration size these states were designed around. Pass nil to draw the
    /// image at its natural size, which is what an SF Symbol needs: stretching a symbol to the
    /// illustration frame distorts it.
    var imageSize: CGSize?

    public init(localizedStrings: LocalizedStrings, image: UIImage?, imageColor: UIColor?, numberOfFilters: Int?, imageSize: CGSize? = CGSize(width: 132, height: 118)) {
        self.localizedStrings = localizedStrings
        self.image = image
        self.imageColor = imageColor
        self.numberOfFilters = numberOfFilters
        self.imageSize = imageSize
    }

    func filterString(localizedStrings: LocalizedStrings) -> AttributedString? {
        guard let numberOfFilters else {
            return nil
        }
        return localizedStrings.attributedFilterString?(numberOfFilters)
    }
}


public enum WMFEmptyViewStateType {
    case noItems
    case filter
}

