import Foundation
import WidgetKit

@objc(WMFWidgetController)
public final class WidgetController: NSObject {

    // MARK: Nested Types

    public enum SupportedWidget: String {
        case pictureOfTheDay = "org.wikipedia.widgets.potd"

        public var identifier: String {
            return self.rawValue
        }
    }

    // MARK: Properties

	@objc public static let shared = WidgetController()

    // MARK: Public

	@objc public func reloadAllWidgets() {
		if #available(iOS 14.0, *) {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

}
