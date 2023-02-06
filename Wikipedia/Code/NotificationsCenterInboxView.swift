import SwiftUI
import WMF

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

struct NotificationsCenterInboxItemView: View {
    @ObservedObject var itemViewModel: NotificationsCenterInboxViewModel.ItemViewModel
    let theme: Theme
    
    var body: some View {
        Button(action: {
            itemViewModel.isSelected.toggle()
        }) {
            HStack {
                let iconColor = theme.colors.icon ?? UIColor.white
                let iconBackgroundColor = theme.colors.iconBackground ?? theme.colors.secondaryText
                if let iconName = itemViewModel.iconName {
                    NotificationsCenterIconImage(iconName: iconName, iconColor: Color(iconColor), iconBackgroundColor: Color(iconBackgroundColor), padding: 6)
                }
                Text(itemViewModel.title)
                    .foregroundColor(Color(theme.colors.primaryText))
                Spacer()
                if itemViewModel.isSelected {
                    Image(systemName: "checkmark")
                        .font(Font.body.weight(.semibold))
                        .foregroundColor(Color(theme.colors.link))
                }
            }
        }
        .listRowBackground(Color(theme.colors.paperBackground).edgesIgnoringSafeArea([.all]))
    }
}

struct NotificationsCenterInboxView: View {

    @Environment (\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: NotificationsCenterInboxViewModel
    let doneAction: () -> Void
    
    var body: some View {
            List {
                ForEach(viewModel.sections) { section in
                    let header = Text(section.header)
                        .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                    let footer = Text(section.footer)
                        .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                    Section(header: header, footer: footer) {
                        ForEach(section.items) { item in
                            NotificationsCenterInboxItemView(itemViewModel: item, theme: viewModel.theme)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
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
            .listBackgroundColor(Color(viewModel.theme.colors.baseBackground))
            .navigationBarTitle(Text(WMFLocalizedString("notifications-center-inbox-title", value: "Projects", comment: "Navigation bar title text for the inbox view presented from notifications center. Allows for filtering out notifications by Wikimedia project type.")), displayMode: .inline)
            .onAppear(perform: {
                if #unavailable(iOS 16) {
                    UITableView.appearance().backgroundColor = UIColor.clear
                }
            })
            .onDisappear(perform: {
                if #unavailable(iOS 16) {
                    UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
                }
            })
    }
}
