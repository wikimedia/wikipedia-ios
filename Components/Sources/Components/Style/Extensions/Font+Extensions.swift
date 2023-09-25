import SwiftUI

/// Allows convenience initialization from WKFont to SwiftUI.Font for use in SwiftUI views
extension Font {

	static func `for`(_ wkFont: WKFont) -> Font {
		return Font(WKFont.for(wkFont))
	}

}
