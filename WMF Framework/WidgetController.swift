import Foundation
import WidgetKit

public final class WidgetController {

    // MARK: Nested Types

    public enum SupportedWidget: String {
        case pictureOfTheDay = "org.wikipedia.widgets.potd"

        public var identifier: String {
            return self.rawValue
        }
    }

    // MARK: Properties

	public static let shared = WidgetController()

    // MARK: Public

	public func reloadAllWidgets() {
		if #available(iOS 14.0, *) {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}

}
