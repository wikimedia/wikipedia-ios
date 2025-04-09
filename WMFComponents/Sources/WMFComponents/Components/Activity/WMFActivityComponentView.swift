import SwiftUI

public struct WMFActivityComponentView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let activityItem: ActivityItem

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(activityItem: ActivityItem) {
        self.activityItem = activityItem
    }

    public var body: some View {
        HStack {
            Image(activityItem.imageName)
                .foregroundStyle(Color(theme.link))
            VStack {
                Text(activityItem.title)
                    .font(Font(WMFFont.for(.boldHeadline)))
                Text(activityItem.subtitle)
                    .font(Font(WMFFont.for(.subheadline)))
                Button(activityItem.onViewTitle) {
                    activityItem.onViewTap()
                }
                .foregroundStyle(Color(theme.link))
            }
        }
    }
}

