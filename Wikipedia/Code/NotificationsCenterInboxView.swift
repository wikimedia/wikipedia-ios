import SwiftUI
import WMF
import Components

struct NotificationsCenterIconImage: View {
    let iconName: String
    let iconColor: Color
    let iconBackgroundColor: Color
    let padding: Int
    
    var body: some View {
        Image(iconName)
            .padding(CGFloat(padding))
            .foregroundColor(iconColor)
            .background(iconBackgroundColor)
            .cornerRadius(6)
            .padding(.trailing, 6)
    }
}

struct NotificationsCenterInboxView: View {

    @Environment (\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: NotificationsCenterInboxViewModel
    let doneAction: () -> Void
    
    var body: some View {
        WKFormView(viewModel: viewModel.formViewModel)
            .navigationBarItems(
                trailing:
                    Button(action: {
                        doneAction()
                    }) {
                        Text(CommonStrings.doneTitle)
                            .fontWeight(Font.Weight.semibold)
                            .foregroundColor(Color(viewModel.theme.colors.primaryText))
                        }
            )
            .padding(.horizontal, horizontalSizeClass == .regular ? (UIFont.preferredFont(forTextStyle: .body).pointSize) : 0)
            .navigationBarTitle(Text(WMFLocalizedString("notifications-center-inbox-title", value: "Projects", comment: "Navigation bar title text for the inbox view presented from notifications center. Allows for filtering out notifications by Wikimedia project type.")), displayMode: .inline)
    }
}
