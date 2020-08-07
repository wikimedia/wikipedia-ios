import Foundation
import WidgetKit

public final class WidgetController {

	public static let shared = WidgetController()
	
	public func reloadAllWidgets() {
		if #available(iOS 14.0, *) {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

}
