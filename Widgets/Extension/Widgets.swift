import WidgetKit
import SwiftUI

@main
struct WikipediaWidgets: WidgetBundle {

	@WidgetBundleBuilder
	var body: some Widget {
		PictureOfTheDayWidget()
		OnThisDayWidget()
        // We can support more widgets just by adding them here
	}

}
