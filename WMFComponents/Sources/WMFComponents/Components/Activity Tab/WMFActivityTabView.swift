import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel

    @State private var animatedGlobalEditCount: Int = 0
    @State private var hasShownGlobalEditsCard: Bool = false

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollViewReader { proxy in
            if viewModel.authenticationState == .loggedIn {
                if !viewModel.customizeViewModel.isTimelineOfBehaviorOn, !viewModel.customizeViewModel.isTimeSpentReadingOn, !viewModel.customizeViewModel.isEditingInsightsOn, !viewModel.customizeViewModel.isReadingInsightsOn {
                    customizedEmptyState()
                } else {
                    loggedInList(proxy: proxy)
                }
            } else {
                if viewModel.customizeViewModel.isTimelineOfBehaviorOn {
                    loggedOutList(proxy: proxy)
                } else {
                    customizedEmptyState()
                }
            }
        }
    }

    private func loggedInList(proxy: ScrollViewProxy) -> some View {
        List {
            Section {
                VStack(spacing: 16) {
                    if viewModel.customizeViewModel.isTimeSpentReadingOn {
                        headerView
                            .accessibilityElement()
                            .accessibilityLabel(viewModel.articlesReadViewModel.usernamesReading)
                            .accessibilityHint(viewModel.localizedStrings.onWikipediaiOS)
                        
                        VStack(alignment: .center, spacing: 8) {
                            hoursMinutesRead
                                .accessibilityLabel(viewModel.hoursMinutesRead)
                            Text(viewModel.localizedStrings.timeSpentReading)
                                .font(Font(WMFFont.for(.semiboldHeadline)))
                                .foregroundColor(Color(uiColor: theme.text))
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel("\(viewModel.hoursMinutesRead), \(viewModel.localizedStrings.timeSpentReading)")
                    }

                    if viewModel.customizeViewModel.isReadingInsightsOn {
                        articlesReadModule(proxy: proxy)
                            .padding(.horizontal, 16)
                        savedArticlesModule
                            .padding(.horizontal, 16)
                        
                        if !viewModel.articlesReadViewModel.topCategories.isEmpty {
                            topCategoriesModule(categories: viewModel.articlesReadViewModel.topCategories)
                                .padding(.horizontal, 16)
                                .accessibilityElement()
                                .accessibilityLabel(viewModel.localizedStrings.topCategories)
                                .accessibilityValue(viewModel.articlesReadViewModel.topCategories.joined(separator: ", "))
                        }
                    }
                    
                    if viewModel.customizeViewModel.isEditingInsightsOn {
                        if let globalEditCount = viewModel.globalEditCount, globalEditCount > 0 {
                            HStack {
                                YourImpactHeaderView(title: viewModel.localizedStrings.yourImpact)
                                Spacer()
                            }
                            .padding(.top, 12)
                            
                            totalEditsView(amount: animatedGlobalEditCount)
                                .padding(.horizontal, 16)
                                .onAppear {
                                    if !hasShownGlobalEditsCard {
                                        hasShownGlobalEditsCard = true
                                        animatedGlobalEditCount = 0
                                        withAnimation(.easeOut(duration: 0.6)) {
                                            animatedGlobalEditCount = globalEditCount
                                        }
                                    } else {
                                        animatedGlobalEditCount = globalEditCount
                                    }
                                }
                                .onChange(of: globalEditCount) { newValue in
                                    withAnimation(.easeOut(duration: 0.6)) {
                                        animatedGlobalEditCount = newValue
                                    }
                                }
                        }
                    }
                }
                .padding(.bottom, 16)
                .listRowInsets(EdgeInsets())
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(uiColor: theme.paperBackground), location: 0),
                            Gradient.Stop(color: Color(uiColor: theme.softEditorBlue), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .listRowSeparator(.hidden)

            if viewModel.customizeViewModel.isTimelineOfBehaviorOn {
                timelineSectionsList()
                    .id("timelineSection")
            }
        }
        .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        .scrollContentBackground(.hidden)
        .listStyle(.grouped)
        .listCustomSectionSpacing(0)
        .onAppear {
            viewModel.fetchData(fromAppearance: true)
        }
    }

    private func loggedOutList(proxy: ScrollViewProxy) -> some View {
        List {
            if viewModel.shouldShowLogInPrompt {
                Section {
                    loggedOutView
                        .accessibilityElement(children: .contain)
                        .listRowInsets(EdgeInsets())
                }
                .listRowSeparator(.hidden)
            }

            timelineSectionsList()
        }
        .scrollContentBackground(.hidden)
        .listStyle(.grouped)
        .listCustomSectionSpacing(0)
        .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        .onAppear {
            viewModel.fetchData(fromAppearance: true)
        }
    }
    
    private func totalEditsView(amount: Int) -> some View {
        WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .globeAmericas, font: WMFFont.boldCaption1),
            title: viewModel.localizedStrings.totalEdits,
            dateText: nil,
            amount: amount,
            onTapModule: {
                viewModel.onTapGlobalEdits?()
            }
        )
        // .padding(.top, 20)
    }

    private func timelineSectionsList() -> some View {
        ForEach(viewModel.sections) { section in
            TimelineSectionView(activityViewModel: viewModel, section: section)
        }
    }

    private var headerView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(viewModel.articlesReadViewModel.usernamesReading)
                .foregroundColor(Color(uiColor: theme.text))
                .font(Font(WMFFont.for(.boldHeadline)))
                .frame(maxWidth: .infinity, alignment: .center)
            Text(viewModel.localizedStrings.onWikipediaiOS)
                .font(.custom("Menlo", size: 11, relativeTo: .caption2))
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(Color(uiColor: theme.softEditorBlue))
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var loggedOutView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(viewModel.localizedStrings.loggedOutTitle)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                Spacer()
                WMFCloseButton(action: {
                   viewModel.closeLoginPrompt()
                })
                .buttonStyle(BorderlessButtonStyle())
            }
            Text(viewModel.localizedStrings.loggedOutSubtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.text))
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.didTapPrimaryLoggedOutCTA?()
                }) {
                    HStack(spacing: 8) {
                        if let icon = WMFSFSymbolIcon.for(symbol: .personFilled) {
                            Image(uiImage: icon)
                        }
                        Text(viewModel.localizedStrings.loggedOutPrimaryCTA)
                    }
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.paperBackground))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: theme.link))
                    .cornerRadius(8)
                }
                .buttonStyle(BorderlessButtonStyle())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .multilineTextAlignment(.leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: theme.paperBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: theme.baseBackground), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(viewModel.localizedStrings.loggedOutTitle). \(viewModel.localizedStrings.loggedOutSubtitle)")
        .background(Color(uiColor: theme.paperBackground))
    }

    private var hoursMinutesRead: some View {
        Text(viewModel.hoursMinutesRead)
            .font(Font(WMFFont.for(.boldTitle1)))
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 221/255, green: 51/255, blue: 51/255),   // #DD3333
                        Color(red: 1.0, green: 149/255, blue: 0),           // #FF9500
                        Color(red: 1.0, green: 204/255, blue: 51/255),      // #FFCC33
                        Color(red: 102/255, green: 153/255, blue: 1.0)      // #6699FF
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Text(viewModel.hoursMinutesRead)
                        .font(Font(WMFFont.for(.boldTitle1)))
                )
            )
    }

    private func articlesReadModule(proxy: ScrollViewProxy) -> some View {
        WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .bookPages, font: WMFFont.boldCaption1),
            title: viewModel.localizedStrings.totalArticlesRead,
            dateText: viewModel.articlesReadViewModel.dateTimeLastRead,
            amount: viewModel.articlesReadViewModel.totalArticlesRead,
            onTapModule: {
                withAnimation(.easeInOut) {
                    proxy.scrollTo("timelineSection", anchor: .top)
                }
            },
            content: {
                articlesReadGraph(weeklyReads: viewModel.articlesReadViewModel.weeklyReads)
            }
        )
    }

    private var savedArticlesModule: some View {

        Group {
            let thumbURLs = viewModel.articlesSavedViewModel.articlesSavedThumbURLs
            let displayCount = min(thumbURLs.count, 3)
            let remaining = viewModel.articlesSavedViewModel.articlesSavedAmount - displayCount

            WMFActivityTabInfoCardView(
                icon: WMFSFSymbolIcon.for(symbol: .bookmark, font: WMFFont.boldCaption1),
                title: viewModel.localizedStrings.articlesSavedTitle,
                dateText: viewModel.articlesSavedViewModel.dateTimeLastSaved,
                amount: viewModel.articlesSavedViewModel.articlesSavedAmount,
                onTapModule: {
                    viewModel.articlesSavedViewModel.onTapSaved?()
                },
                content: {

                    if !thumbURLs.isEmpty {
                        savedArticlesImages(thumbURLs: thumbURLs, totalSavedCount: viewModel.articlesSavedViewModel.articlesSavedAmount, remaining: remaining)
                    }
                }
            )
        }
    }

    private func showPlus(displayCount: Int, totalSavedCount: Int) -> Bool {
        if displayCount < 3 && totalSavedCount == 3 {
            return true
        } else if totalSavedCount > 3 {
            return true
        } else {
            return false
        }
    }

    private func savedArticlesImages(thumbURLs: [URL?], totalSavedCount: Int, remaining: Int) -> some View {
        HStack(spacing: 4) {
            let displayCount = min(thumbURLs.count, 3)
            let showPlus = showPlus(displayCount: displayCount, totalSavedCount: totalSavedCount)

            ForEach(Array(thumbURLs.prefix(displayCount)), id: \.self) { imageURL in
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 38, height: 38)
                .clipShape(Circle())
            }

            if showPlus {
                Text("+\(remaining)")
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(Color(uiColor: theme.paperBackground))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color(uiColor: theme.secondaryText))
                    )
            }
        }
    }

    private func articlesReadGraph(weeklyReads: [Int]) -> some View {
        Chart {
            ForEach(weeklyReads.indices, id: \.self) { index in
                BarMark(
                    x: .value(viewModel.localizedStrings.week, index),
                    y: .value(viewModel.localizedStrings.articlesRead, weeklyReads[index] + 1),
                    width: 12
                )
                .foregroundStyle(
                    weeklyReads[index] > 0
                    ? Color(uiColor: theme.accent)
                    : Color(uiColor: theme.newBorder)
                )
                .cornerRadius(1.5)
                .accessibilityLabel("\(viewModel.localizedStrings.week) \(index + 1)")
                .accessibilityValue("\(weeklyReads[index]) \(viewModel.localizedStrings.articlesRead)")
            }
        }
        .accessibilityElement(children: .contain)
        .frame(maxWidth: 54, maxHeight: 45)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.background(.clear) }
    }

    private func topCategoriesModule(categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                if let icon = WMFSFSymbolIcon.for(symbol: .rectangle3) {
                    Image(uiImage: icon)
                }
                Text(viewModel.localizedStrings.topCategories)
                    .foregroundStyle(Color(theme.text))
                    .font(Font(WMFFont.for(.boldCaption1)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(categories.indices, id: \.self) { index in
                let category = categories[index]
                VStack(alignment: .leading, spacing: 16) {
                    Text(category)
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.callout)))
                        .lineLimit(2)

                    if index < categories.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .overlay(
                                Rectangle()
                                    .fill(Color(uiColor: theme.baseBackground))
                                    .frame(height: 1)
                            )
                            .padding(0)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(theme.baseBackground), lineWidth: 0.5)
        )
    }
    
    private func customizedEmptyState() -> some View {
        VStack {
            Spacer()
            if let image = UIImage(named: "empty_activity_tab", in: .module, with: nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 132, height: 118)
            }
            WMFHtmlText(html: viewModel.localizedStrings.customizeEmptyState, styles: summaryStyles)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .multilineTextAlignment(.center)
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.openCustomize()
                        }
                )
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var summaryStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.subheadline), boldFont: WMFFont.for(.boldSubheadline), italicsFont: WMFFont.for(.italicSubheadline), boldItalicsFont: WMFFont.for(.boldItalicSubheadline), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
}

struct TimelineSectionView: View {
    
    let activityViewModel: WMFActivityTabViewModel
    @ObservedObject var section: TimelineViewModel.TimelineSection
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public var body: some View {
        return Section(
            header:
                TimelineHeaderView(activityViewModel: activityViewModel, section: section)
        ) {
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
        
        let tapAction: () -> Void = {
            self.activityViewModel.timelineViewModel.onTap(item)
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
            contextMenuOpenAction: contextMenuOpenAction,
            contextMenuOpenText: activityViewModel.localizedStrings.openArticle,
            deleteItemAction: deleteItemAction,
            deleteAccessibilityLabel: activityViewModel.localizedStrings.deleteAccessibilityLabel)
    }
    
    public var body: some View {
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

struct YourImpactHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let title: String
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        Text(title)
            .font(Font(WMFFont.for(.boldHeadline)))
            .foregroundColor(Color(uiColor: theme.text))
            .textCase(.none)
            .padding(.horizontal, 16)
        .accessibilityAddTraits(.isHeader)
    }
}
