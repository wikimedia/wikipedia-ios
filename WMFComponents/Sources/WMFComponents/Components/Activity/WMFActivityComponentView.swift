import SwiftUI

public struct WMFActivityComponentView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    let activityItem: ActivityItem
    let title: String
    let onButtonTap: (() -> Void)?
    let backgroundColor: UIColor
    let leadingIconColor: UIColor
    let leadingIconName: String
    let trailingIconName: String
    let titleFont: UIFont
    let buttonTitle: String?

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(activityItem: ActivityItem, title: String, onButtonTap: (() -> Void)?, buttonTitle: String? = nil, backgroundColor: UIColor, leadingIconColor: UIColor, leadingIconName: String, trailingIconName: String, titleFont: UIFont) {
        self.activityItem = activityItem
        self.title = title
        self.onButtonTap = onButtonTap
        self.backgroundColor = backgroundColor
        self.leadingIconColor = leadingIconColor
        self.leadingIconName = leadingIconName
        self.trailingIconName = trailingIconName
        self.titleFont = titleFont
        self.buttonTitle = buttonTitle
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 8) {
                Image(leadingIconName, bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color(uiColor: leadingIconColor))
                    .frame(height: 52)
                    .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }

                VStack {
                    Text(title)
                        .foregroundStyle(Color(uiColor: theme.text))
                        .font(Font(titleFont))
                        .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let buttonTitle = buttonTitle, activityItem.type != ActivityTabDisplayType.noEdit {
                        Text(buttonTitle)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(titleFont))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if onButtonTap != nil {
                    // todo: cleanup for system name
                    if trailingIconName == "chevron.forward" {
                        Image(systemName: trailingIconName)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .frame(height: 22, alignment: .trailing)
                            .fontWeight(.bold)
                            .padding(.leading, 16)
                    } else {
                        Image(trailingIconName, bundle: .module)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .frame(height: 22, alignment: .trailing)
                            .fontWeight(.bold)
                            .padding(.leading, 16)
                    }
                    
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background(Color(uiColor: backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(uiColor: theme.darkBorder), lineWidth: 0.5)
                    .frame(minHeight: 96)
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
