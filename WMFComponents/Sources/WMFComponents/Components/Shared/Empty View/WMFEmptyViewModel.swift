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

    public init(localizedStrings: LocalizedStrings, image: UIImage?, imageColor: UIColor?, numberOfFilters: Int?) {
        self.localizedStrings = localizedStrings
        self.image = image
        self.imageColor = imageColor
        self.numberOfFilters = numberOfFilters
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

