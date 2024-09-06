import Foundation
import UIKit

public final class WMFFormItemSelectViewModel: ObservableObject, Identifiable, Equatable {

    public static func == (lhs: WMFFormItemSelectViewModel, rhs: WMFFormItemSelectViewModel) -> Bool {
        return lhs.id == rhs.id
    }

    public let id = UUID()
    let image: UIImage?
    let title: String?
    @Published public var isSelected: Bool
	
	public var isAccessoryRow: Bool
	public var accessoryRowSelectionAction: (() -> Void)?

	public init(image: UIImage? = nil, title: String?, isSelected: Bool, isAccessoryRow: Bool = false, accessoryRowSelectionAction: (() -> Void)? = nil) {
        self.image = image
        self.title = title
        self.isSelected = isSelected
		self.isAccessoryRow = isAccessoryRow
		self.accessoryRowSelectionAction = accessoryRowSelectionAction
    }
}
