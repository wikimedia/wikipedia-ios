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
            .background(Color(theme.paperBackground))
        }
    }

    private func rowView(for section: HistorySection, item: HistoryItem) -> some View {
        WMFPageRow(
            id: item.id,
            titleHtml: item.titleHtml,
            articleDescription: item.description,
            imageURL: item.imageURL,
            isSaved: item.isSaved,
            deleteAccessibilityLabel: viewModel.localizedStrings.deleteSwipeActionLabel,
            shareAccessibilityLabel: viewModel.localizedStrings.shareActionTitle,
            saveAccessibilityLabel: viewModel.localizedStrings.saveForLaterActionTitle,
            unsaveAccessibilityLabel: viewModel.localizedStrings.unsaveActionTitle,
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

    private func getTextForAction(_ item: HistoryItem) -> String {
        if item.isSaved {
            return viewModel.localizedStrings.unsaveActionTitle
        } else {
            return viewModel.localizedStrings.saveForLaterActionTitle
        }
    }

    private func row(for section: HistorySection, _ item: HistoryItem) -> some View {
        Button(action: {
            viewModel.onTap(item)
        }) {
            rowView(for: section, item: item)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(viewModel.localizedStrings.readNowActionTitle) {
                viewModel.onTap(item)
            }
            Button(getTextForAction(item)) {
                viewModel.saveOrUnsave(section: section, item: item)
            }
            Button(viewModel.localizedStrings.shareActionTitle) {
                viewModel.share(section: section, item: item)
            }
        } preview: {
            WMFArticlePreviewView(item: item)
        }
    }

    private func listView() -> some View {
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
                        row(for: section, item)
                            .listRowBackground(Color(theme.paperBackground))
                    }
                }

            }

        }
        .listStyle(.plain)
        .padding(.top, viewModel.topPadding)
        .scrollContentBackground(.hidden)
        .background(Color(theme.paperBackground))
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
