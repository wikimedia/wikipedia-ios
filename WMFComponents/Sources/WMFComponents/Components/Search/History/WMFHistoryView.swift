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
        return Text(viewModel.headerTextForSection(section))
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
                        image: viewModel.emptyViewImage,
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
            shareItemAction: { frame in
                viewModel.share(frame: frame, item: item)
            },
            saveOrUnsaveItemAction: {
                viewModel.saveOrUnsave(item: item)
            }
        )
    }

    private func row(for section: HistorySection, _ item: HistoryItem) -> some View {
        Button(action: {
            viewModel.onTap(item)
        }) {
            rowView(for: section, item: item)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                viewModel.onTap(item)
            } label: {
                Text(viewModel.localizedStrings.readNowActionTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .book) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
            Button {
                viewModel.saveOrUnsave(item: item)
            } label: {
                Text(item.isSaved ? viewModel.localizedStrings.unsaveActionTitle : viewModel.localizedStrings.saveForLaterActionTitle)
                Image(uiImage: item.isSaved ?
                      (WMFSFSymbolIcon.for(symbol: .bookmarkFill) ?? UIImage()) :
                      (WMFSFSymbolIcon.for(symbol: .bookmark) ?? UIImage()))
            }
            .labelStyle(.titleAndIcon)
            Button {
                let frame = viewModel.geometryFrames[item.id] ?? .zero
                viewModel.share(frame: frame, item: item)
            } label: {
                Text(viewModel.localizedStrings.shareActionTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
        } preview: {
            WMFArticlePreviewView(item: item)
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewModel.geometryFrames[item.id] = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        viewModel.geometryFrames[item.id] = newFrame
                    }
            }
            .allowsHitTesting(false)
        )
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
        ZStack {
            Color(theme.paperBackground)
                .ignoresSafeArea()
            if !viewModel.isEmpty {
                listView()
            } else {
                emptyView()
            }
        }
        .onAppear {
            viewModel.loadHistory()
        }
    }

}
