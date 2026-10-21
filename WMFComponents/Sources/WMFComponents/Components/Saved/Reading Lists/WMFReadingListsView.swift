import SwiftUI
import WMFData
import WMFNativeLocalizations

public struct WMFReadingListsView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFReadingListsViewModel
    /// Mirrors `showsAnnouncement` so the card fades in and out instead of popping.
    @State private var isAnnouncementShown = false

    private let deleteTitle = CommonStrings.deleteActionTitle
    private let cancelTitle = CommonStrings.cancelActionTitle
    private let emptyTitle = CommonStrings.readingListsEmptyTitle
    private let emptyMessage = CommonStrings.readingListsEmptyMessage
    private let createNewListTitle = CommonStrings.createNewListTitle

    public init(viewModel: WMFReadingListsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .empty:
                VStack(spacing: 0) {
                    announcementCard
                    emptyState
                }
            case .data:
                listView
            }
        }
        .background(Color(uiColor: appEnvironment.theme.paperBackground))
        .onAppear {
            viewModel.loadReadingLists()
            isAnnouncementShown = showsAnnouncement
        }
        .onChange(of: showsAnnouncement) { _, shows in
            withAnimation {
                isAnnouncementShown = shows
            }
        }
        .alert(
            CommonStrings.deleteReadingListsAlertTitle(readingListsCount: viewModel.pendingDeletion?.count ?? 1),
            isPresented: Binding(
                get: { viewModel.pendingDeletion != nil },
                set: { if !$0 { viewModel.cancelPendingDeletion() } }
            )
        ) {
            Button(cancelTitle, role: .cancel) {
                viewModel.cancelPendingDeletion()
            }
            Button(deleteTitle, role: .destructive) {
                viewModel.confirmPendingDeletion()
            }
        } message: {
            Text(CommonStrings.deleteReadingListsAlertMessage(readingListsCount: viewModel.pendingDeletion?.count ?? 1))
        }
    }

    // MARK: - Discover Announcement

    /// The card shows while the reader is not editing or searching.
    private var showsAnnouncement: Bool {
        viewModel.isAnnouncementVisible && !viewModel.isEditing && viewModel.searchText.isEmpty
    }

    @ViewBuilder
    private var announcementCard: some View {
        if isAnnouncementShown, let announcementViewModel = viewModel.announcementViewModel {
            WMFDiscoverAnnouncementView(viewModel: announcementViewModel)
                .padding(EdgeInsets(top: WMFSpacing.small, leading: WMFSpacing.large, bottom: WMFSpacing.large, trailing: WMFSpacing.large))
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var announcementRow: some View {
        if isAnnouncementShown, let announcementViewModel = viewModel.announcementViewModel {
            WMFDiscoverAnnouncementView(viewModel: announcementViewModel)
                .listRowInsets(EdgeInsets(top: WMFSpacing.small, leading: WMFSpacing.large, bottom: WMFSpacing.large, trailing: WMFSpacing.large))
                .listRowSeparator(.hidden)
                .listRowBackground(Color(uiColor: appEnvironment.theme.paperBackground))
                .transition(.opacity)
        }
    }

    private var emptyState: some View {
        let emptyViewModel = WMFEmptyViewModel(
            localizedStrings: WMFEmptyViewModel.LocalizedStrings(title: emptyTitle, subtitle: emptyMessage, titleFilter: nil, buttonTitle: createNewListTitle, attributedFilterString: nil),
            image: UIImage(named: "reading-lists-empty-state", in: Bundle.module, with: nil),
            imageColor: nil,
            numberOfFilters: nil
        )
        return WMFEmptyView(viewModel: emptyViewModel, type: .noItems, isScrollable: true, mainAction: { viewModel.didTapCreateList?() })
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Saved.readingListsEmptyView)
    }

    private var listView: some View {
        VStack(spacing: 0) {
            List {
                announcementRow
                ForEach(viewModel.rows) { row in
                    let readingList = row.readingList
                    let isSelected = viewModel.selectedIDs.contains(readingList.id)
                    VStack(spacing: 0) {
                        Button {
                            if viewModel.isEditing {
                                viewModel.toggleSelection(for: readingList)
                            } else {
                                viewModel.didTapReadingList?(readingList)
                            }
                        } label: {
                            WMFReadingListRow(viewModel: row, isEditing: viewModel.isEditing, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Saved.readingListCell(readingList.name))

                        Divider()
                            .background(Color(uiColor: appEnvironment.theme.border))
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(uiColor: isSelected ? appEnvironment.theme.batchSelectionBackground : appEnvironment.theme.paperBackground))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !viewModel.isEditing && !readingList.isDefault, let deleteIcon = WMFIcon.delete {
                            Button(role: .destructive) {
                                viewModel.requestDeletion(of: [readingList])
                            } label: {
                                Image(uiImage: deleteIcon)
                            }
                            .accessibilityIdentifier(AccessibilityIdentifiers.Saved.rowDeleteSwipeButton)
                            .tint(Color(uiColor: appEnvironment.theme.destructive))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .wmfReportsScrollToTop()
            .accessibilityIdentifier(AccessibilityIdentifiers.Saved.readingListsView)
            .refreshable {
                await viewModel.refresh()
            }
            .background(Color(uiColor: appEnvironment.theme.paperBackground))

            if viewModel.isEditing {
                editingToolbar
            }
        }
    }

    private var editingToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(uiColor: appEnvironment.theme.border))
            HStack {
                Button {
                    viewModel.deleteSelectedReadingLists()
                } label: {
                    Text(deleteTitle)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(viewModel.hasSelection ? Color(uiColor: appEnvironment.theme.destructive) : Color(uiColor: appEnvironment.theme.secondaryText))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Saved.batchEditToolbarButton("delete"))
                .disabled(!viewModel.hasSelection)
                .frame(maxWidth: .infinity)
            }
            .padding([.top, .bottom], 12)
            .background(Color(uiColor: appEnvironment.theme.midBackground))
        }
    }
}
