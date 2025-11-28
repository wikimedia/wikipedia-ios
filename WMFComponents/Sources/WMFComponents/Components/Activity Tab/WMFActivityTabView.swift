import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel
    @ObservedObject private var timelineViewModel: TimelineViewModel
    @ObservedObject private var savedViewModel: ArticlesSavedViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
        self.timelineViewModel = viewModel.timelineViewModel
        self.savedViewModel = viewModel.articlesSavedViewModel
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

    private func getPreviewViewModel(from item: TimelineItem) -> WMFArticlePreviewViewModel {
        let summary = timelineViewModel.pageSummaries[item.id]

        return WMFArticlePreviewViewModel(
            url: item.url,
            titleHtml: item.titleHtml,
            description: summary?.description ?? item.description,
            imageURLString: summary?.thumbnailURL?.absoluteString ?? item.imageURLString,
            isSaved: false,
            snippet: summary?.extract ?? item.snippet
        )
    }

    private var historyView: some View {
       return Group {
           let timeline = timelineViewModel.timeline
            if !timeline.isEmpty {
                // Sort dates descending
                ForEach(timeline.keys.sorted(by: >), id: \.self) { date in
                    timelineSection(for: date, pages: timeline[date] ?? [])
                        .listRowSeparator(.hidden)
                }
            }
        }
    }
    
    private func timelineSection(for date: Date, pages: [TimelineItem]) -> some View {
        let sortedPages = pages.sorted(by: { $0.date > $1.date })
        let calendar = Calendar.current

        let title: String
        let subtitle: String
        if calendar.isDateInToday(date) {
            title = viewModel.localizedStrings.todayTitle
            subtitle = viewModel.formatDate(date)
        } else if calendar.isDateInYesterday(date) {
            title = viewModel.localizedStrings.yesterdayTitle
            subtitle = viewModel.formatDate(date)
        } else {
            title = viewModel.formatDate(date)
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
            ForEach(sortedPages.indices, id: \.self) { index in
                pageRow(page: sortedPages[index], section: date)
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


    private func pageRow(page: TimelineItem, section: Date) -> some View {
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

        let summary = timelineViewModel.pageSummaries[page.id]
        let initialThumbnailURLString = summary?.thumbnailURL?.absoluteString ?? page.imageURLString

        return WMFPageRow(
            needsLimitedFontSize: false,
            id: page.id,
            titleHtml: page.pageTitle.replacingOccurrences(of: "_", with: " "),
            articleDescription: {
                if let desc = summary?.description, !desc.isEmpty {
                    return desc
                } else if let pageDesc = page.description, !pageDesc.isEmpty {
                    return pageDesc
                } else if let extract = summary?.extract, !extract.isEmpty {
                    return extract
                } else {
                    return nil
                }
            }(),
            imageURLString: initialThumbnailURLString,
            titleLineLimit: 1,
            isSaved: false,
            showsSwipeActions: true,
            deleteItemAction: { timelineViewModel.deletePage(item: page) },
            loadImageAction: { imageURLString in
                try? await timelineViewModel.loadImage(imageURLString: imageURLString)
            },
            iconImage: iconImage
        )
        .contentShape(Rectangle())
        .onTapGesture {
            timelineViewModel.onTap(page)
        }
        .contextMenu {
            Button {
                timelineViewModel.onTap(page)
            } label: {
                HStack {
                    Text(viewModel.localizedStrings.openArticle)
                        .font(Font(WMFFont.for(.mediumSubheadline)))
                    Spacer()
                    if let icon = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline) {
                        Image(uiImage: icon)
                    }
                }
            }
        } preview: {
            if summary != nil {
                WMFArticlePreviewView(viewModel: getPreviewViewModel(from: page))
            }
        }
        .task {
            _ = await timelineViewModel.fetchSummary(for: page)
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
                    let thumbURLs = savedViewModel.articlesSavedThumbURLs
                    if !thumbURLs.isEmpty {
                        savedArticlesImages(thumbURLs: thumbURLs, totalSavedCount: savedViewModel.articlesSavedAmount)
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
                    .font(Font(WMFFont.for(.caption2Semibold)))
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
        .padding(.trailing, 6)
        .padding(.bottom, 0)
    }

    private func topCategoriesModule(categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                if let icon = WMFSFSymbolIcon.for(symbol: .rectangle3, font: WMFFont.boldCaption1) {
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
                        .padding(0)

                    if index < categories.count - 1 {
                        Divider()
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
}
