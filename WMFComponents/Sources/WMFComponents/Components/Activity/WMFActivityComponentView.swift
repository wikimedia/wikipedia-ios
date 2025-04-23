import SwiftUI

public struct WMFActivityComponentView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let activityItem: ActivityItem
    let title: String
    let onButtonTap: (() -> Void)?
    let shouldDisplayButton: Bool
    let backgroundColor: UIColor
    let iconColor: UIColor
    let iconName: String

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(activityItem: ActivityItem, title: String, onButtonTap: (() -> Void)?, shouldDisplayButton: Bool, backgroundColor: UIColor, iconColor: UIColor, iconName: String) {
        self.activityItem = activityItem
        self.title = title
        self.onButtonTap = onButtonTap
        self.shouldDisplayButton = shouldDisplayButton
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.iconName = iconName
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 12) {
                Image(iconName, bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color(uiColor: iconColor))
                    .frame(height: 52) 
                    .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }

                Text(title)
                    .foregroundStyle(Color(uiColor: theme.text))
                    .font(activityItem.type == .noEdit ? Font(WMFFont.for(.headline)) : Font(WMFFont.for(.boldHeadline)))
                    .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                    .frame(maxWidth: .infinity, alignment: .leading)

                if activityItem.type == .noEdit && onButtonTap != nil {
                    Image("activity-link", bundle: .module)
                        .foregroundStyle(Color(uiColor: theme.link))
                        .frame(height: 22, alignment: .trailing)
                        .fontWeight(.bold)
                } else if onButtonTap != nil {
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(Color(uiColor: theme.link))
                        .frame(height: 22, alignment: .trailing)
                        .fontWeight(.bold)
                } else {
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(uiColor: iconColor.withAlphaComponent(0.3)), lineWidth: 1)
            )
        }
        .onTapGesture {
            if let onButtonTap {
                onButtonTap()
            }
        }
        .padding(2)
    }
}
