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
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if viewModel.authenticationState == .loggedIn {
                    if !viewModel.customizeViewModel.isTimelineOfBehaviorOn, !viewModel.customizeViewModel.isTimeSpentReadingOn, !viewModel.customizeViewModel.isEditingInsightsOn, !viewModel.customizeViewModel.isReadingInsightsOn {
                        customizedEmptyState()
                    } else {
                        loggedInList(proxy: proxy)
                    }
                } else {
                    loggedOutList(proxy: proxy)
                }
            }
        }
        .onAppear {
            viewModel.fetchData(fromAppearance: true)
        }
    }

    private func loggedInList(proxy: ScrollViewProxy) -> some View {
        List {
            if viewModel.customizeViewModel.isTimeSpentReadingOn || viewModel.customizeViewModel.isReadingInsightsOn {
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
                            savedArticlesModule
                            
                            if viewModel.shouldShowExploreCTA {
                                exploreCTA
                                    .padding(.vertical, 12)
                            }
                            
                            if !viewModel.articlesReadViewModel.topCategories.isEmpty {
                                topCategoriesModule(categories: viewModel.articlesReadViewModel.topCategories)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
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
            }
                        
            if viewModel.customizeViewModel.isEditingInsightsOn && viewModel.shouldShowYourImpactHeader {
                
                Section(header: YourImpactHeaderView(viewModel: viewModel)) {
                    
                    VStack(spacing: 16) {
                        
                        if let mostViewedArticlesViewModel = viewModel.mostViewedArticlesViewModel {
                            TopViewedEditsView(viewModel: viewModel, mostViewedViewModel: mostViewedArticlesViewModel)
                        }
                        
                        if let contributionsViewModel = viewModel.contributionsViewModel {
                            ContributionsView(viewModel: contributionsViewModel)
                        }
                        
                        if viewModel.allTimeImpactViewModel != nil || viewModel.recentActivityViewModel != nil || viewModel.articleViewsViewModel != nil {
                            CombinedImpactView(allTimeImpactViewModel: viewModel.allTimeImpactViewModel, recentActivityViewModel: viewModel.recentActivityViewModel, articleViewsViewModel: viewModel.articleViewsViewModel)
                        }
                        
                        if let globalEditCount = viewModel.globalEditCount, globalEditCount > 0 {
                            totalEditsView(amount: animatedGlobalEditCount)
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
                    .padding(.horizontal, 16)
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
            }
            
            if viewModel.customizeViewModel.isTimelineOfBehaviorOn {
                timelineSectionsList()
                    .id("timelineSection")
            }
        }
        .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        .scrollContentBackground(.hidden)
        .listStyle(.grouped)
        .listCustomSectionSpacing(0)
    }
    
    private var exploreCTA: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(viewModel.localizedStrings.lookingForSomethingNew)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .foregroundStyle(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            WMFSmallButton(configuration: .init(style: .primary), title: viewModel.localizedStrings.exploreWikipedia, action: {
                // This is purposefully left empty because the whole container has an on tap
            })
        }
        .onTapGesture {
            viewModel.exploreWikipedia()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func loggedOutList(proxy: ScrollViewProxy) -> some View {
        if viewModel.sections.count == 0 {
            VStack {
                Section {
                    loggedOutView
                        .accessibilityElement(children: .contain)
                        .listRowInsets(EdgeInsets())
                }
                .listRowSeparator(.hidden)
                
                HStack {
                    Spacer()
                    WMFEmptyView(
                        appEnvironment: appEnvironment,
                        viewModel: viewModel.emptyViewModel,
                        type: .noItems,
                        isScrollable: false)
                    Spacer()
                }
            }
            .frame(maxHeight: .infinity)
            .listRowSeparator(.hidden)
            .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        } else {
            List {
                Section {
                    loggedOutView
                        .accessibilityElement(children: .contain)
                        .listRowInsets(EdgeInsets())
                }
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.grouped)
            .listCustomSectionSpacing(0)
            .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    private func totalEditsView(amount: Int) -> some View {

        let cardView = WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .globeAmericas),
            title: viewModel.localizedStrings.totalEditsAcrossProjects,
            dateText: nil,
            onTapModule: {
                viewModel.onTapGlobalEdits?()
            }, content: {
                HStack(alignment: .bottom) {
                    Text("\(amount)")
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldTitle1)))
                    Spacer()
                }
            }
        )
        
        let formattedAmount = amountAccessibilityLabel(for: amount)
        let accessibilityLabel: String = [viewModel.localizedStrings.totalEditsAcrossProjects, formattedAmount].joined(separator: ",")
        
        return cardView.accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
        
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

        let cardView = WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .bookPages),
            title: viewModel.localizedStrings.totalArticlesRead,
            dateText: viewModel.articlesReadViewModel.dateTimeLastRead,
            onTapModule: {
                withAnimation(.easeInOut) {
                    proxy.scrollTo("timelineSection", anchor: .top)
                }
            },
            content: {
                HStack(alignment: .bottom) {
                    Text("\(viewModel.articlesReadViewModel.totalArticlesRead)")
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldTitle1)))
                    Spacer()
                    articlesReadGraph(weeklyReads: viewModel.articlesReadViewModel.weeklyReads)
                }
            }
        )
        
        let formattedAmount = amountAccessibilityLabel(for: viewModel.articlesReadViewModel.totalArticlesRead)
        let accessibilityLabel: String = [viewModel.localizedStrings.totalArticlesRead, viewModel.articlesReadViewModel.dateTimeLastRead, formattedAmount].joined(separator: ",")
        
        return cardView
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }

    private var savedArticlesModule: some View {

        let thumbURLs = viewModel.articlesSavedViewModel.articlesSavedThumbURLs
        let displayCount = min(thumbURLs.count, 3)
        let remaining = viewModel.articlesSavedViewModel.articlesSavedAmount - displayCount

        let cardView = WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .bookmark),
            title: viewModel.localizedStrings.articlesSavedTitle,
            dateText: viewModel.articlesSavedViewModel.dateTimeLastSaved,
            onTapModule: {
                viewModel.articlesSavedViewModel.onTapSaved?()
            },
            content: {
                HStack(alignment: .bottom) {
                    Text("\(viewModel.articlesSavedViewModel.articlesSavedAmount)")
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.boldTitle1)))
                    Spacer()
                    if !thumbURLs.isEmpty {
                        savedArticlesImages(thumbURLs: thumbURLs, totalSavedCount: viewModel.articlesSavedViewModel.articlesSavedAmount, remaining: remaining)
                    }
                }
            }
        )
        
        let formattedAmount = amountAccessibilityLabel(for: viewModel.articlesSavedViewModel.articlesSavedAmount)
        let accessibilityLabel: String = [viewModel.localizedStrings.articlesSavedTitle, viewModel.articlesSavedViewModel.dateTimeLastSaved, formattedAmount].joined(separator: ",")
        
        return cardView
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
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
        let maxReads = weeklyReads.max() ?? 1
        let chartHeight: CGFloat = 45
        let minBarHeight: CGFloat = 4
        
        return VStack {
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weeklyReads.indices, id: \.self) { index in
                    let percentage = maxReads > 0 ? CGFloat(weeklyReads[index]) / CGFloat(maxReads) : 0
                    let barHeight = weeklyReads[index] > 0 ? chartHeight * percentage : minBarHeight
                    
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(weeklyReads[index] > 0
                            ? Color(uiColor: theme.accent)
                            : Color(uiColor: theme.newBorder))
                        .frame(width: 12, height: barHeight)
                        .accessibilityLabel("\(viewModel.localizedStrings.week) \(index + 1)")
                        .accessibilityValue("\(weeklyReads[index]) \(viewModel.localizedStrings.articlesRead)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .frame(maxWidth: 54, maxHeight: chartHeight)
        .padding(.trailing, 8)
    }

    private func topCategoriesModule(categories: [String]) -> some View {
        
        let cardView = WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .rectangle3, font: WMFFont.boldCaption1),
            title: viewModel.localizedStrings.topCategories,
            dateText: nil,
            onTapModule: nil,
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(categories.indices, id: \.self) { index in
                        let category = categories[index]
                        Text(category)
                            .foregroundStyle(Color(theme.text))
                            .font(Font(WMFFont.for(.callout)))
                            .frame(maxWidth: .infinity, alignment: .leading)
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
        )
        
        let accessibilityLabel = viewModel.localizedStrings.topCategories
        let accessibilityValue = viewModel.articlesReadViewModel.topCategories.joined(separator: ", ")
        
        return cardView
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
    }
    
    private func amountAccessibilityLabel(for amount: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private func customizedEmptyState() -> some View {
        WMFSimpleEmptyStateView(imageName: "empty_activity_tab", openCustomize: viewModel.openCustomize, title: viewModel.localizedStrings.customizeEmptyState)
            .frame(maxWidth: .infinity)
    }
}
