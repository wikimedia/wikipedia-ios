import SwiftUI

/// The Discover card pinned above a Saved segment, with the spacing both segments share.
struct WMFSavedDiscoverHeaderView: View {

    let header: WMFSavedDiscoverHeaderViewModel.Header
    let viewModel: WMFSavedDiscoverHeaderViewModel

    var body: some View {
        Group {
            switch header {
            case .entryCard:
                WMFDiscoverEntryCardView(viewModel: viewModel.entryCardViewModel)
            case .announcement:
                WMFDiscoverAnnouncementView(viewModel: viewModel.announcementViewModel)
            }
        }
        .padding(EdgeInsets(top: WMFSpacing.small, leading: WMFSpacing.large, bottom: WMFSpacing.large, trailing: WMFSpacing.large))
        .readableWidth()
    }
}
