import SwiftUI

/// Allows convenience initialization from WMFFont to SwiftUI.Font for use in SwiftUI views
extension Font {

	static func `for`(_ wmfFont: WMFFont) -> Font {
		return Font(WMFFont.for(wmfFont))
	}

}
