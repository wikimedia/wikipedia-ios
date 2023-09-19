import UIKit

public class WKEmptyViewModel: ObservableObject {

    public struct LocalizedStrings {
        public var title: String
        public var subtitle: String
        public var titleFilter: String
        public var buttonTitle: String
        public var attributedFilterString: ((Int) -> AttributedString)

        public init(title: String, subtitle: String, titleFilter: String, buttonTitle: String, attributedFilterString: @escaping ((Int) -> AttributedString)) {
            self.title = title
            self.subtitle = subtitle
            self.titleFilter = titleFilter
            self.buttonTitle = buttonTitle
            self.attributedFilterString = attributedFilterString
        }
    }

    var localizedStrings: LocalizedStrings
    var image: UIImage
    @Published var numberOfFilters: Int

    public init(localizedStrings: LocalizedStrings, image: UIImage, numberOfFilters: Int) {
        self.localizedStrings = localizedStrings
        self.image = image
        self.numberOfFilters = numberOfFilters
    }
    
    func filterString(localizedStrings: LocalizedStrings) -> AttributedString {
        return localizedStrings.attributedFilterString(numberOfFilters)
    }
}


public enum WKEmptyViewStateType {
    case noItems
    case filter
}

