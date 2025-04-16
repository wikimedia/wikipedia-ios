import SwiftUI

public struct WMFActivityComponentView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    let activityItem: ActivityItem
    let title: String?
    let onButtonTap: (() -> Void)?

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(activityItem: ActivityItem, title: String?, onButtonTap: (() -> Void)?) {
        self.activityItem = activityItem
        self.title = title
        self.onButtonTap = onButtonTap
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activityItem.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color(theme.link))
                .frame(width: 42, alignment: .center)
            VStack(alignment: .leading, spacing: 8) {
                Text(activityItem.title)
                    .font(Font(WMFFont.for(.boldHeadline)))
                if let title, let onButtonTap {
                    Button(title) {
                        onButtonTap()
                    }
                    .foregroundStyle(Color(theme.link))
                }
            }
        }
    }
}

