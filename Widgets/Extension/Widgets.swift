import WidgetKit
import SwiftUI

@main
struct WikipediaWidgets: WidgetBundle {

	@WidgetBundleBuilder
	var body: some Widget {
		PictureOfTheDayWidget()
		// We can support more widgets just by adding them here
	}

}
