
import SwiftUI
import WMF

struct NotificationsCenterInboxItemView: View {
    @ObservedObject var itemViewModel: NotificationsCenterInboxViewModel.ItemViewModel
    let theme: Theme
    let didUpdateFiltersCallback: () -> Void
    
    var body: some View {
        Button(action: {
            itemViewModel.isSelected.toggle()
            didUpdateFiltersCallback()
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
    }
}

struct NotificationsCenterInboxView: View {
    
    let viewModel: NotificationsCenterInboxViewModel
    let didUpdateFiltersCallback: () -> Void
    let doneAction: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sections) { section in
                    let header = Text(section.header)
                        .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                    let footer = Text(section.footer)
                        .foregroundColor(Color(viewModel.theme.colors.secondaryText))
                    Section(header: header, footer: footer) {
                        ForEach(section.items) { item in
                            NotificationsCenterInboxItemView(itemViewModel: item, theme: viewModel.theme, didUpdateFiltersCallback: didUpdateFiltersCallback)
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
            .navigationBarTitle(Text("Projects"), displayMode: .inline)
        }
    }
}
