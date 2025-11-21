import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel
    @ObservedObject private var timelineViewModel: TimelineViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
        self.timelineViewModel = viewModel.timelineViewModel
    }

    public var body: some View {
        ScrollViewReader { proxy in
            if viewModel.isLoggedIn {
                List {
                    Section {
                        VStack(spacing: 20) {
                            headerView

                            VStack(alignment: .center, spacing: 8) {
                                hoursMinutesRead
                                Text(viewModel.localizedStrings.timeSpentReading)
                                    .font(Font(WMFFont.for(.semiboldHeadline)))
                                    .foregroundColor(Color(uiColor: theme.text))
                            }
                            .frame(maxWidth: .infinity)

                            articlesReadModule(proxy: proxy)
                            savedArticlesModule

                            if !viewModel.articlesReadViewModel.topCategories.isEmpty {
                                topCategoriesModule(categories: viewModel.articlesReadViewModel.topCategories)
                            }
                        }
                        .padding(16)
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
                    
                    historyView
                        .id("timelineSection")
                }
                .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
                .scrollContentBackground(.hidden)
                .listStyle(.grouped)
                .onAppear {
                    viewModel.fetchData()
                    viewModel.hasSeenActivityTab()
                }
            } else {
                List {
                    Section {
                        VStack(alignment: .leading) {
                            loggedOutView
                            historyView
                                .id("timelineSection")
                        }
                        .padding(16)
                        .listRowInsets(EdgeInsets())
                        .background(Color(uiColor: theme.paperBackground))
                    }
                    .listRowSeparator(.hidden)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
                .scrollContentBackground(.hidden)
                .listStyle(.grouped)
                .onAppear {
                    viewModel.fetchData()
                    viewModel.hasSeenActivityTab()
                }
            }
        }
    }

    private var historyView: some View {
        ForEach(timelineViewModel.sections) { section in
            timelineSection(section: section)
                .listRowSeparator(.hidden)
        }
    }
    
    private func timelineSection(section: TimelineViewModel.TimelineSection) -> some View {
        let calendar = Calendar.current

        let title: String
        let subtitle: String
        if calendar.isDateInToday(section.date) {
            title = viewModel.localizedStrings.todayTitle
            subtitle = viewModel.formatDate(section.date)
        } else if calendar.isDateInYesterday(section.date) {
            title = viewModel.localizedStrings.yesterdayTitle
            subtitle = viewModel.formatDate(section.date)
        } else {
            title = viewModel.formatDate(section.date)
            subtitle = ""
        }

        return Section(
            header:
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
                .padding(.bottom, 20)
        ) {
            ForEach(section.items) { item in
                pageRow(page: item, sectionID: section.id)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 20)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color(uiColor: theme.paperBackground))
        .padding(.horizontal, 16)
    }


    private func pageRow(page: TimelineItem, sectionID: TimelineViewModel.TimelineSection.ID) -> some View {
        let iconImage: UIImage?
        switch page.itemType {
        case .standard:
            iconImage = nil
        case .edit:
            iconImage = WMFSFSymbolIcon.for(symbol: .pencil, font: .callout)
        case .read:
            iconImage = WMFSFSymbolIcon.for(symbol: .textPage, font: .callout)
        case .save:
            iconImage = WMFSFSymbolIcon.for(symbol: .bookmark, font: .callout)
        }
        
        let deleteItemAction: () -> Void = {
            self.timelineViewModel.deletePage(item: page, sectionID: sectionID)
        }
        
        let tapAction: () -> Void = {
            self.timelineViewModel.onTap(page)
        }
        
        let contextMenuOpenAction: () -> Void = {
            self.timelineViewModel.onTap(page)
        }

        let pageRowViewModel = WMFAsyncPageRowViewModel(
            wmfpage: page.page,
            id: page.id,
            title: page.pageTitle.replacingOccurrences(of: "_", with: " "),
            iconImage: iconImage,
            tapAction: tapAction,
            contextMenuOpenAction: contextMenuOpenAction,
            contextMenuOpenText: viewModel.localizedStrings.openArticle,
            deleteItemAction: deleteItemAction,
            deleteAccessibilityLabel: viewModel.localizedStrings.deleteAccessibilityLabel)

        return WMFAsyncPageRow(viewModel: pageRowViewModel)
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
    }

    private var loggedOutView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.localizedStrings.loggedOutTitle)
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                Spacer()
                WMFCloseButton(action: {
                    // todo close
                })
            }
            Text(viewModel.localizedStrings.loggedOutSubtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.text))
            HStack(spacing: 12) {
                Button(action: {
                    // todo navigate
                }) {
                    HStack(spacing: 3) {
                        if let icon = WMFSFSymbolIcon.for(symbol: .personFilled) {
                            Image(uiImage: icon)
                        }
                        Text(viewModel.localizedStrings.loggedOutPrimaryCTA)
                    }
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(uiColor: theme.paperBackground))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: theme.link))
                    .cornerRadius(40)
                }
                Button(action: {
                    // todo navigate
                }) {
                    Text(viewModel.localizedStrings.loggedOutSecondaryCTA)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: theme.text))
                        .padding(.horizontal, 10)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .multilineTextAlignment(.leading)
        .padding(16) // interior padding
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: theme.paperBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: theme.baseBackground), lineWidth: 0.5)
                )
        )
        .padding(16) // exterior padding
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
            WMFActivityTabInfoCardView(
                icon: WMFSFSymbolIcon.for(symbol: .bookmark, font: WMFFont.boldCaption1),
                title: viewModel.localizedStrings.articlesSavedTitle,
                dateText: viewModel.articlesSavedViewModel.dateTimeLastSaved,
                amount: viewModel.articlesSavedViewModel.articlesSavedAmount,
                onTapModule: {
                    viewModel.articlesSavedViewModel.navigateToSaved?()
                },
                content: {
                    let thumbURLs = viewModel.articlesSavedViewModel.articlesSavedThumbURLs
                    if !thumbURLs.isEmpty {
                        savedArticlesImages(thumbURLs: thumbURLs, totalSavedCount: viewModel.articlesSavedViewModel.articlesSavedAmount)
                    }
                }
            )
        }
    }

    private func savedArticlesImages(thumbURLs: [URL?], totalSavedCount: Int) -> some View {
        HStack(spacing: 4) {
            let displayCount = min(thumbURLs.count, 3)
            let showPlus = totalSavedCount > 3

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
                let remaining = totalSavedCount - 3
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
}
