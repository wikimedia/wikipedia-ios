import Foundation
import UIKit

public final class WKFormItemSelectViewModel: ObservableObject, Identifiable, Equatable {

    public static func == (lhs: WKFormItemSelectViewModel, rhs: WKFormItemSelectViewModel) -> Bool {
        return lhs.id == rhs.id
    }

    public let id = UUID()
    let image: UIImage?
    let title: String?
    @Published public var isSelected: Bool

    public init(image: UIImage? = nil, title: String?, isSelected: Bool) {
        self.image = image
        self.title = title
        self.isSelected = isSelected
    }
}
