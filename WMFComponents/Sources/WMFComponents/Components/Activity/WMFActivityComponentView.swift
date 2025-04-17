import SwiftUI

public struct WMFActivityComponentView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let activityItem: ActivityItem
    let title: String?
    let onButtonTap: (() -> Void)?
    let shouldDisplayButton: Bool

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(activityItem: ActivityItem, title: String?, onButtonTap: (() -> Void)?, shouldDisplayButton: Bool) {
        self.activityItem = activityItem
        self.title = title
        self.onButtonTap = onButtonTap
        self.shouldDisplayButton = shouldDisplayButton
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let imageName = activityItem.imageName {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color(theme.link))
                    .frame(width: 42, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(activityItem.title)
                    .font(Font(WMFFont.for(.boldHeadline)))
                if let subtitle = activityItem.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.headline)))
                }
                if shouldDisplayButton {
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
}

