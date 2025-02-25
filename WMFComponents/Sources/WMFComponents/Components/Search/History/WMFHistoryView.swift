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

    public var body: some View {

        // TODO: Data loading needs fixing
        if !viewModel.isEmpty {
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
                            WMFPageRow(
                                id: item.id,
                                titleHtml: item.titleHtml,
                                articleDescription: item.description,
                                imageURL: item.imageURL,
                                isSaved: true,  // Fix
                                deleteItemAction: { _ in
                                    viewModel.delete(section: section, item: item)
                                    refreshId = UUID()
                                },
                                shareItemAction: { _ in
                                    viewModel.share(section: section, item: item)
                                },
                                saveItemAction: { _ in
                                    viewModel.save(section: section, item: item)
                                }
                            )
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, viewModel.topPadding)
            .id(refreshId)
            .onAppear {
                refreshId = UUID()
                viewModel.loadHistory()
            }
        } else {
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
    }
}
