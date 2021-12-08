
import SwiftUI
import WMF

struct NotificationsCenterInboxItemView: View {
    @ObservedObject var itemViewModel: NotificationsCenterInboxViewModel.ItemViewModel
    let didUpdateFiltersCallback: () -> Void
    
    var body: some View {
        Button(action: {
            itemViewModel.isSelected.toggle()
            didUpdateFiltersCallback()
        }) {
            HStack {
                Text(itemViewModel.title)
                Spacer()
                if (itemViewModel.isSelected) {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct NotificationsCenterInboxView: View {
    
    let viewModel: NotificationsCenterInboxViewModel
    let didUpdateFiltersCallback: () -> Void
    
    var body: some View {
        //NavigationView {
            List {
                ForEach(viewModel.sections) { section in
                    Section(header: Text(section.header)) {
                        ForEach(section.items) { item in
                            NotificationsCenterInboxItemView(itemViewModel: item, didUpdateFiltersCallback: didUpdateFiltersCallback)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Projects"))
        //}
    }
}
