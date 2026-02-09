import WidgetKit
import SwiftUI

@main
struct WikipediaWidgets: WidgetBundle {

	@WidgetBundleBuilder
	var body: some Widget {
		PictureOfTheDayWidget()
		OnThisDayWidget()
        TopReadWidget()
        FeaturedArticleWidget()
        ReadingStreakWidget()
        #if DEBUG
        SearchWidget()
        LockscreenSearchWidget()
        #endif
	}

}
