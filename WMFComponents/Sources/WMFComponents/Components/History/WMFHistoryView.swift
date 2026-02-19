import SwiftUI
import WMFData

public struct WMFHistoryView: View {

    // MARK: - Properties

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFHistoryViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    // MARK: - Lifecycle

    public init(viewModel: WMFHistoryViewModel) {
        self.viewModel = viewModel
        UITableView.appearance().alwaysBounceVertical = true
    }

    // MARK: - Private methods

    private func headerViewForSection(_ section: HistorySection) -> some View {
        return Text(viewModel.headerTextForSection(section))
            .font(Font(WMFFont.for(.boldHeadline)))
            .foregroundStyle(Color(uiColor: theme.text))
    }

    private func emptyView() -> some View {
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
            imageColor: nil,
            numberOfFilters: 0
        )
        return WMFEmptyView(viewModel: emptyViewModel, type: .noItems, isScrollable: true)
                .ignoresSafeArea()
    }

    private func rowView(for section: HistorySection, item: HistoryItem) -> some View {
        WMFPageRow(
            needsLimitedFontSize: false,
            id: item.id,
            titleHtml: item.titleHtml,
            articleDescription: item.description,
            imageURLString: item.imageURLString,
            titleLineLimit: 0,
            isSaved: item.isSaved,
            deleteAccessibilityLabel: viewModel.localizedStrings.deleteSwipeActionLabel,
            shareAccessibilityLabel: viewModel.localizedStrings.shareActionTitle,
            saveAccessibilityLabel: viewModel.localizedStrings.saveForLaterActionTitle,
            unsaveAccessibilityLabel: viewModel.localizedStrings.unsaveActionTitle,
            showsSwipeActions: true,
            deleteItemAction: {
                viewModel.delete(section: section, item: item)
            },
            shareItemAction: { frame in
                viewModel.share(frame: frame, item: item)
            },
            saveOrUnsaveItemAction: {
                viewModel.saveOrUnsave(item: item, in: section)
            },
            loadImageAction: { imageURLString in
                return try? await viewModel.loadImage(imageURLString: imageURLString)
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
                Text(viewModel.localizedStrings.openArticleActionTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
            Button {
                viewModel.saveOrUnsave(item: item, in: section)
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
            WMFArticlePreviewView(viewModel: getPreviewViewModel(from:item))
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
            
            Section {
                Text(viewModel.localizedStrings.historyHeaderTitle)
                    .font(Font(WMFFont.for(.boldTitle3)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .padding(.top, viewModel.topPadding)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(theme.paperBackground))
            
            ForEach(viewModel.sections) { section in
                
                Section {
                    
                    // Header as a regular row so that they aren't sticky
                    headerViewForSection(section)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(theme.paperBackground))
                    
                    ForEach(section.items) { item in
                        row(for: section, item)
                            .listRowBackground(Color(theme.paperBackground))
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
        .scrollContentBackground(.hidden)
        .background(Color(theme.paperBackground))
        .ignoresSafeArea(edges: .top)
    }

    private func getPreviewViewModel(from item: HistoryItem) -> WMFArticlePreviewViewModel {
        return WMFArticlePreviewViewModel(url: item.url, titleHtml: item.titleHtml, description: item.description, imageURLString: item.imageURLString, isSaved: item.isSaved, snippet: item.snippet)
    }

    // MARK: - Public methods

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
