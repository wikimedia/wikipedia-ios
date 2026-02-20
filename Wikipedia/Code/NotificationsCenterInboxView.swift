import SwiftUI
import WMF
import WMFComponents

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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: NotificationsCenterInboxViewModel
    
    var body: some View {
        WMFFormView(viewModel: viewModel.formViewModel)
            .padding(.horizontal, horizontalSizeClass == .regular ? WMFFont.for(.footnote).pointSize : 0)
    }
}
