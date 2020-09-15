import Foundation
import WidgetKit

@objc(WMFWidgetController)
public final class WidgetController: NSObject {

    // MARK: Nested Types

    public enum SupportedWidget: String {
        case pictureOfTheDay = "org.wikimedia.wikipedia.widgets.potd"
        case onThisDay = "org.wikimedia.wikipedia.widgets.onThisDay"
        case topRead = "org.wikimedia.wikipedia.widgets.topRead"

        public var identifier: String {
            return self.rawValue
        }
    }

    // MARK: Properties

	@objc public static let shared = WidgetController()

    // MARK: Public

	@objc public func reloadAllWidgetsIfNecessary() {
        guard !Bundle.main.isAppExtension else {
            return
        }
		if #available(iOS 14.0, *) {
			WidgetCenter.shared.reloadAllTimelines()
		}
	}
    
    /// For requesting background time from widgets
    /// - Parameter reason: the reason for requesting background time
    /// - Parameter userCompletion: completion to be called from within the background task completion
    /// - Returns a completion block to be called when the background task is completed
    public func startBackgroundTask<T>(reason: String, userCompletion: @escaping (T) ->  Void) -> (T) -> Void  {
        let processInfo = ProcessInfo.processInfo
        let start = processInfo.beginActivity(options: .background, reason: reason)
        return { entry in
            userCompletion(entry)
            processInfo.endActivity(start)
        }
    }

}
