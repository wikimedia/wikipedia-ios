import SwiftUI
import WMFData

public struct WMFHistoryView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @State private var refreshId = UUID()

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFHistoryViewModel

    public init(viewModel: WMFHistoryViewModel) {
        self.viewModel = viewModel
    }

    private func headerViewForSection(_ section: HistorySection) -> some View {
        return Text(DateFormatter.wmfFullDateFormatter.string(from: section.dateWithoutTime))
            .font(Font(WMFFont.for(.boldHeadline)))
            .foregroundStyle(Color(uiColor: theme.text))
    }

    private func emptyView() -> some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: true) {
                VStack {
                    let locStrings = WMFEmptyViewModel.LocalizedStrings(
                        title: viewModel.localizedStrings.emptyViewTitle,
                        subtitle: viewModel.localizedStrings.emptyViewSubtitle,
                        titleFilter: nil,
                        buttonTitle: nil,
                        attributedFilterString: nil
                    )
                    let emptyViewModel = WMFEmptyViewModel(
                        localizedStrings: locStrings,
                        image: nil,
                        imageColor: .blue,
                        numberOfFilters: 0
                    )
                    WMFEmptyView(viewModel: emptyViewModel, type: .noItems)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
        }
    }

    private func rowView(for section: HistorySection, item: HistoryItem) -> some View {
        WMFPageRow(
            id: item.id,
            titleHtml: item.titleHtml,
            articleDescription: item.description,
            imageURL: item.imageURL,
            isSaved: item.isSaved,
            deleteItemAction: {
                viewModel.delete(section: section, item: item)
                refreshId = UUID()
            },
            shareItemAction: {
                viewModel.share(section: section, item: item)
            },
            saveOrUnsaveItemAction: {
                viewModel.saveOrUnsave(section: section, item: item)
            }
        )
    }

    public func listView() -> some View {
        List {
            Text(viewModel.localizedStrings.title)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundStyle(Color(uiColor: theme.text))
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ForEach(viewModel.sections) { section in
                Section(header: headerViewForSection(section)) {
                    ForEach(section.items) { item in
                        Button(action: {
                            viewModel.onTap(item: item)
                        }) {
                            rowView(for: section, item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.plain)
        .padding(.top, viewModel.topPadding)
        .id(refreshId)
        .onAppear {
            refreshId = UUID()
            viewModel.loadHistory()
        }
    }

    public var body: some View {

        // TODO: Data loading needs fixing
        if !viewModel.isEmpty {
            listView()
        } else {
            emptyView()
        }
    }
}
