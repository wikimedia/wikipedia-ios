import WMFComponents
import SwiftUI
import WMF

struct NotificationsCenterFilterItemView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var itemViewModel: NotificationsCenterFiltersViewModel.ItemViewModel
    let theme: Theme

    var body: some View {
        
        Group {
            
            switch itemViewModel.selectionType {
            case .checkmark:
                
                Button(action: {
                    itemViewModel.toggleSelectionForCheckmarkType()
                }) {
                    HStack {
                        Text(itemViewModel.title)
                            .foregroundColor(Color(theme.colors.primaryText))
                        Spacer()
                        if itemViewModel.isSelected {
                            Image(systemName: "checkmark")
                                .font(Font(WMFFont.for(.boldCallout)))
                                .foregroundColor(Color(theme.colors.link))
                        }
                    }
                }
            case .toggle(let type):
                
                HStack {

                    let iconColor = theme.colors.paperBackground
                    let iconBackgroundColor = type.imageBackgroundColorWithTheme(theme)
                    
                    let iconName = type.imageName
                    NotificationsCenterIconImage(iconName: iconName, iconColor: Color(iconColor), iconBackgroundColor: Color(iconBackgroundColor), padding: 0)
                    
                    let customBinding = $itemViewModel.isSelected.didSet { (state) in
                        itemViewModel.toggleSelectionForToggleType()
                    }
                    
                    Toggle(isOn: customBinding) {
                        customLabelForToggle(type: type)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(theme.colors.accent)))
                }
            case .toggleAll:
                Toggle(itemViewModel.title, isOn: $itemViewModel.isSelected.didSet { (state) in
                    itemViewModel.toggleSelectionForAll()
                })
                .foregroundColor(Color(theme.colors.primaryText))
                .toggleStyle(SwitchToggleStyle(tint: Color(theme.colors.accent)))
            }
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? WMFFont.for(.callout).pointSize : 0)
        .listRowBackground(Color(theme.colors.paperBackground).edgesIgnoringSafeArea([.all]))
    }
    
    private func customLabelForToggle(type: RemoteNotificationFilterType) -> some View {
        Group {
            switch type {
            case .loginAttempts, // represents both known and unknown devices
                    .loginSuccess:

                let subtitle = type == .loginAttempts ? WMFLocalizedString("notifications-center-type-title-login-attempts-subtitle", value: "Failed login attempts to your account", comment: "Subtitle of \"Login attempts\" notification type filter toggle. Represents failed logins from both a known and unknown device.")
                 :  CommonStrings.notificationsCenterLoginSuccessDescription
                 
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemViewModel.title)
                        .foregroundColor(Color(theme.colors.primaryText))
                        .font(Font(WMFFont.for(.callout)))
                    Text(subtitle)
                        .foregroundColor(Color(theme.colors.secondaryText))
                        .font(Font(WMFFont.for(.footnote)))
                }
            default:
                Text(itemViewModel.title)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(theme.colors.primaryText))
            }
        }
        
    }
}

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

struct NotificationsCenterFilterView: View {

    let viewModel: NotificationsCenterFiltersViewModel
    let doneAction: () -> Void
    
    var body: some View {
            List {
                ForEach(viewModel.sections) { section in
                    
                    if let title = section.title {
                        let header = Text(title).foregroundColor(Color(viewModel.theme.colors.secondaryText))
                        if let footer = section.footer {
                            let footer = Text(footer)
                                .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                            Section(header: header, footer: footer) {
                                ForEach(section.items) { item in
                                    NotificationsCenterFilterItemView(itemViewModel: item, theme: viewModel.theme)
                                }
                            }
                        } else {
                            Section(header: header) {
                                ForEach(section.items) { item in
                                    NotificationsCenterFilterItemView(itemViewModel: item, theme: viewModel.theme)
                                }
                            }
                        }
                    } else {
                        Section {
                            ForEach(section.items) { item in
                                NotificationsCenterFilterItemView(itemViewModel: item, theme: viewModel.theme)
                            }
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
            .listBackgroundColor(Color(viewModel.theme.colors.baseBackground))
            .navigationBarTitle(Text(WMFLocalizedString("notifications-center-filters-title", value: "Filters", comment: "Navigation bar title text for the filters view presented from notifications center. Allows for filtering by read status and notification type.")), displayMode: .inline)
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
