
import SwiftUI

struct NotificationsCenterFilterItemView: View {
    @ObservedObject var itemViewModel: NotificationsCenterFiltersViewModel.ItemViewModel
    let theme: Theme
    
    var body: some View {
        
        switch itemViewModel.selectionType {
        case .checkmark:
            
            Button(action: {
                itemViewModel.toggleSelectionForCheckmarkType()
            }) {
                HStack {
                    Text(itemViewModel.title)
                        .foregroundColor(Color(theme.colors.primaryText))
                    Spacer()
                    if (itemViewModel.isSelected) {
                        Image(systemName: "checkmark")
                            .font(Font.body.weight(.semibold))
                            .foregroundColor(Color(theme.colors.link))
                    }
                }
            }
            .listRowBackground(Color(theme.colors.paperBackground).edgesIgnoringSafeArea([.all]))
        case .toggle(let remoteNotificationType):
            
            HStack {
                
                let iconColor = theme.colors.paperBackground
                let iconBackgroundColor = remoteNotificationType.imageBackgroundColorWithTheme(theme)
                if let iconName = remoteNotificationType.imageName {
                    NotificationsCenterIconImage(iconName: iconName, iconColor: Color(iconColor), iconBackgroundColor: Color(iconBackgroundColor), padding: 0)
                }
                
                if #available(iOS 14.0, *) {
                    Toggle(itemViewModel.title, isOn: $itemViewModel.isSelected)
                        .foregroundColor(Color(theme.colors.primaryText))
                        .toggleStyle(SwitchToggleStyle(tint: Color(theme.colors.accent)))
                } else {
                    Toggle(itemViewModel.title, isOn: $itemViewModel.isSelected)
                        .foregroundColor(Color(theme.colors.primaryText))
                }
            }
            .listRowBackground(Color(theme.colors.paperBackground).edgesIgnoringSafeArea([.all]))
        }
        
        
    }
}

struct NotificationsCenterFilterView: View {
    
    let viewModel: NotificationsCenterFiltersViewModel
    let doneAction: () -> Void
    
    var body: some View {
            List {
                ForEach(viewModel.sections) { section in
                    let header = Text(section.title)
                        .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                    Section(header: header) {
                        ForEach(section.items) { item in
                            NotificationsCenterFilterItemView(itemViewModel: item, theme: viewModel.theme)
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
                          Text("Done")
                            .fontWeight(Font.Weight.semibold)
                            .foregroundColor(Color(viewModel.theme.colors.primaryText))
                        }
            )
            .background(Color(viewModel.theme.colors.baseBackground).edgesIgnoringSafeArea(.all))
            .navigationBarTitle(Text("Filters"), displayMode: .inline)
            .onAppear(perform: {
                    UITableView.appearance().backgroundColor = UIColor.clear
            })
            .onDisappear(perform: {
                
                UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
            })
    }
}
