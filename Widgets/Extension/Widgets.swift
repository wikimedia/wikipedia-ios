import WidgetKit
import SwiftUI

@main
struct WikipediaWidgets: WidgetBundle {

    @WidgetBundleBuilder
    var body: some Widget {
        PictureOfTheDayWidget()
        RandomWidget()
        OnThisDayWidget()
        TopReadWidget()
        FeaturedArticleWidget()
        SearchWidget()
        LockscreenSearchWidget()
    }

}
