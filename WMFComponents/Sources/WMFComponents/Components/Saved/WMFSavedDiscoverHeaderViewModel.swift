import Foundation
import Combine

/// Decides which Discover card the Saved tab pins above its lists. The entry card wins once the
/// reader turned Discover on. The onboarding card shows until then, for readers in the experiment
/// group who did not answer it. One instance is shared by the All articles and Reading lists segments.
@MainActor
public final class WMFSavedDiscoverHeaderViewModel: ObservableObject {

    public enum Header: Equatable {
        case entryCard
        case announcement
    }

    @Published public private(set) var header: Header?

    public let announcementViewModel: WMFDiscoverAnnouncementViewModel
    public let entryCardViewModel: WMFDiscoverEntryCardViewModel

    private var cancellables = Set<AnyCancellable>()

    public init(announcementViewModel: WMFDiscoverAnnouncementViewModel, entryCardViewModel: WMFDiscoverEntryCardViewModel) {
        self.announcementViewModel = announcementViewModel
        self.entryCardViewModel = entryCardViewModel
        self.header = Self.header(showsEntryCard: entryCardViewModel.isVisible, showsAnnouncement: announcementViewModel.isVisible)
        bind()
    }

    private func bind() {
        entryCardViewModel.$isVisible
            .combineLatest(announcementViewModel.$isVisible)
            .map { showsEntryCard, showsAnnouncement in
                Self.header(showsEntryCard: showsEntryCard, showsAnnouncement: showsAnnouncement)
            }
            .removeDuplicates()
            .sink { [weak self] header in
                self?.header = header
            }
            .store(in: &cancellables)
    }

    static func header(showsEntryCard: Bool, showsAnnouncement: Bool) -> Header? {
        if showsEntryCard {
            return .entryCard
        }
        return showsAnnouncement ? .announcement : nil
    }

    /// Re-reads both cards' state, for example when Saved appears.
    public func refresh() {
        announcementViewModel.refresh()
        entryCardViewModel.refresh()
    }
}
