import SwiftUI
import WMFData
import Charts
import Foundation

struct TimelineSectionView: View {
    let activityViewModel: WMFActivityTabViewModel
    @ObservedObject var section: TimelineViewModel.TimelineSection

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        Section(header: EmptyView()) {
            Group {
                TimelineHeaderView(activityViewModel: activityViewModel, section: section)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color(uiColor: theme.paperBackground))

            if activityViewModel.shouldShowEmptyState {
                emptyState
                    .listRowSeparator(.hidden)
            } else {
                ForEach(section.items) { item in
                    TimelineRowView(activityViewModel: activityViewModel, section: section, item: item)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(uiColor: theme.paperBackground))
                }
            }
        }
        .listRowBackground(Color(uiColor: theme.paperBackground))
        .padding(.horizontal, 16)
    }
    
    private var emptyState: some View {
        HStack {
            Spacer()
            WMFEmptyView(viewModel: activityViewModel.emptyViewModel, type: .noItems, isScrollable: false)
            Spacer()
        }
    }
}

struct TimelineRowView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let activityViewModel: WMFActivityTabViewModel
    let section: TimelineViewModel.TimelineSection
    let item: TimelineItem
    
    var pageRowViewModel: WMFAsyncPageRowViewModel {
        var iconImage: UIImage?
        var iconAccessiblityLabel: String
        switch item.itemType {
        case .standard:
            iconImage = nil
            iconAccessiblityLabel = ""
        case .edit:
            iconImage = WMFSFSymbolIcon.for(symbol: .pencil, font: .callout)
            iconAccessiblityLabel = activityViewModel.localizedStrings.edited
        case .read:
            iconImage = WMFSFSymbolIcon.for(symbol: .textPage, font: .callout)
            iconAccessiblityLabel = activityViewModel.localizedStrings.read
        case .saved:
            iconImage = WMFSFSymbolIcon.for(symbol: .bookmark, font: .callout)
            iconAccessiblityLabel = activityViewModel.localizedStrings.saved
        }
        
        // Hide icon if logged out
        if activityViewModel.authenticationState == .loggedOut {
            iconImage = nil
            iconAccessiblityLabel = ""
        }
        
        var deleteItemAction: (() -> Void)? = nil
        if item.itemType == .read {
            deleteItemAction = {
                self.activityViewModel.timelineViewModel.deletePage(item: item, section: section)
            }
        }
        
        let tapAction: () -> Void
        if item.itemType == .edit {
            tapAction = {
                self.activityViewModel.timelineViewModel.onTapEdit(item)
            }
        } else {
            tapAction = {
                self.activityViewModel.timelineViewModel.onTap(item)
            }
        }
        
        let contextMenuOpenAction: () -> Void = {
            self.activityViewModel.timelineViewModel.onTap(item)
        }

        return WMFAsyncPageRowViewModel(
            id: item.id,
            title: item.pageTitle.replacingOccurrences(of: "_", with: " "),
            projectID: item.projectID,
            iconImage: iconImage,
            iconAccessibilityLabel: iconAccessiblityLabel,
            tapAction: tapAction,
            contextMenuOpenAction: item.itemType == .edit ? nil : contextMenuOpenAction,
            contextMenuOpenText: item.itemType == .edit ? nil : activityViewModel.localizedStrings.openArticle,
            deleteItemAction: deleteItemAction,
            deleteAccessibilityLabel: activityViewModel.localizedStrings.deleteAccessibilityLabel,
            bottomButtonTitle: item.itemType == .edit ? activityViewModel.localizedStrings.viewChanges : nil)
    }
    
    var body: some View {
        return WMFAsyncPageRow(viewModel: pageRowViewModel)
    }
}

struct TimelineHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let activityViewModel: WMFActivityTabViewModel
    let section: TimelineViewModel.TimelineSection
    
    var title: String {
        let calendar = Calendar.current

        let title: String
        if calendar.isDateInToday(section.date) {
            title = activityViewModel.localizedStrings.todayTitle
        } else if calendar.isDateInYesterday(section.date) {
            title = activityViewModel.localizedStrings.yesterdayTitle
        } else {
            title = activityViewModel.formatDate(section.date)
        }
        
        return title
    }
    
    var subtitle: String {
        let calendar = Calendar.current

        let subtitle: String
        if calendar.isDateInToday(section.date) {
            subtitle = activityViewModel.formatDate(section.date)
        } else if calendar.isDateInYesterday(section.date) {
            subtitle = activityViewModel.formatDate(section.date)
        } else {
            subtitle = ""
        }
        
        return subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(Font(WMFFont.for(.boldTitle3)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .textCase(.none)
            }
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .textCase(.none)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.bottom, 20)
        .padding(.top, 28)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

