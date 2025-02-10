import SwiftUI

public struct WMFHistoryView: View {

    @ObservedObject var viewModel: WMFHistoryViewModel
    
    public init(viewModel: WMFHistoryViewModel) {
        self.viewModel = viewModel
    }
    
    private func headerViewForSection(_ section: WMFHistoryViewModel.Section) -> some View {
        return Text(DateFormatter.wmfFullDateFormatter.string(from: section.dateWithoutTime))
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(header: headerViewForSection(section)) {
                    ForEach(section.items) { item in
                        WMFPageRow(id: item.id, titleHtml: item.titleHtml, description: item.description, imageURL: item.imageURL, deleteItemAction: { identifier in
                            viewModel.delete(section: section, item: item)
                        })
                    }
                }
            }
        }
        .listStyle(.grouped)
        .padding([.top], viewModel.topPadding)
    }
}
