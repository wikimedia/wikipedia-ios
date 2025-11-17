import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
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

                        articlesReadModule
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

                Section(
                    header: Text("Articles")
                        .font(.headline)
                        .foregroundColor(Color(uiColor: theme.text))
                ) {
                    historyView
                }
            }
            .listStyle(.plain)
            .onAppear {
                viewModel.fetchData()
            }
            .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
        } else {
            loggedOutView
        }
    }

    // MARK: - History / Timeline

    private func getPreviewViewModel(from item: TimelineItem) -> WMFArticlePreviewViewModel {
        WMFArticlePreviewViewModel(
            url: item.url,
            titleHtml: item.titleHtml,
            description: item.description,
            imageURLString: item.imageURLString,
            isSaved: false,
            snippet: item.snippet
        )
    }

    private var historyView: some View {
        Group {
            if let timeline = viewModel.timelineViewModel.timeline, !timeline.isEmpty {
                ForEach(timeline.keys.sorted(by: >), id: \.self) { date in
                    timelineSection(for: date, pages: timeline[date] ?? [])
                }
            } else {
                Text("No history")
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .padding()
            }
        }
    }

    private func timelineSection(for date: Date, pages: [TimelineItem]) -> some View {
        let sortedPages = pages.sorted(by: { $0.date > $1.date })
        let calendar = Calendar.current

        let sectionHeader: String
        if calendar.isDateInToday(date) {
            sectionHeader = viewModel.articlesReadViewModel.dateTimeLastRead
        } else {
            sectionHeader = viewModel.formatDateTime(date)
        }

        return Section(
            header: Text(sectionHeader)
                .font(.headline)
                .foregroundColor(Color(uiColor: theme.text))
        ) {
            ForEach(sortedPages, id: \.id) { page in
                pageView(page: page)
            }
            .onDelete { indexSet in
                viewModel.deletePages(at: indexSet, for: date)
            }
        }
    }

    private func pageView(page: TimelineItem) -> some View {
        let itemID = page.id
        let summary = viewModel.timelineViewModel.pageSummaries[itemID]

        return VStack(alignment: .leading, spacing: 4) {
            Text(page.titleHtml)
                .font(.body)
                .foregroundColor(Color(uiColor: theme.link))

            if let description = summary?.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            Task {
                _ = await viewModel.fetchSummary(for: page)
            }
        }
        .contextMenu {
            Button {
                // TODO: hook up navigation to article
                print("Open article action")
            } label: {
                Label("Open Article", systemImage: "chevron.forward")
            }
        } preview: {
            if summary != nil {
                WMFArticlePreviewView(viewModel: getPreviewViewModel(from: page))
            }
        }
    }

    // MARK: - Header / Logged Out

    private var headerView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(viewModel.articlesReadViewModel.usernamesReading)
                .foregroundColor(Color(uiColor: theme.text))
                .font(Font(WMFFont.for(.boldBody)))
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
                    // TODO: close activity tab sheet / navigation
                })
            }

            Text(viewModel.localizedStrings.loggedOutSubtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.text))

            HStack(spacing: 12) {
                Button(action: {
                    // TODO: navigate to login / account
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
                    // TODO: navigate to dismiss / learn more
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: theme.paperBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: theme.baseBackground), lineWidth: 0.5)
                )
        )
        .padding(16)
    }

    // MARK: - Modules

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

    private var articlesReadModule: some View {
        WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .bookPages, font: WMFFont.boldCaption1),
            title: viewModel.localizedStrings.totalArticlesRead,
            dateText: viewModel.articlesReadViewModel.dateTimeLastRead,
            amount: viewModel.articlesReadViewModel.totalArticlesRead,
            onTapModule: {
                // TODO: Navigate to full history view
                print("Tapped Articles Read module")
            },
            content: {
                articlesReadGraph(weeklyReads: viewModel.articlesReadViewModel.weeklyReads)
            }
        )
    }

    private var savedArticlesModule: some View {
        WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .bookmark, font: WMFFont.boldCaption1),
            title: viewModel.localizedStrings.articlesSavedTitle,
            dateText: viewModel.articlesSavedViewModel.dateTimeLastSaved,
            amount: viewModel.articlesSavedViewModel.articlesSavedAmount,
            onTapModule: {
                viewModel.navigateToSaved?()
            },
            content: {
                let thumbURLs = viewModel.articlesSavedViewModel.articlesSavedThumbURLs
                if !thumbURLs.isEmpty {
                    savedArticlesImages(
                        thumbURLs: thumbURLs,
                        totalSavedCount: viewModel.articlesSavedViewModel.articlesSavedAmount
                    )
                }
            }
        )
    }

    private func savedArticlesImages(thumbURLs: [URL?], totalSavedCount: Int) -> some View {
        HStack(spacing: 4) {
            let displayCount = min(thumbURLs.count, 3)
            let showPlus = totalSavedCount > displayCount

            ForEach(0..<displayCount, id: \.self) { index in
                let imageURL = thumbURLs[index]
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
                let remaining = totalSavedCount - displayCount
                Text(viewModel.localizedStrings.remaining(remaining))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
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
            }
        }
        .frame(maxWidth: 54, maxHeight: 45)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.clear)
        }
    }

    private func topCategoriesModule(categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                if let icon = WMFSFSymbolIcon.for(symbol: .rectangle3) {
                    Image(uiImage: icon)
                }
                Text(viewModel.localizedStrings.topCategories)
                    .foregroundStyle(Color(uiColor: theme.text))
                    .font(Font(WMFFont.for(.boldCaption1)))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(categories.indices, id: \.self) { index in
                let category = categories[index]
                VStack(alignment: .leading, spacing: 16) {
                    Text(category)
                        .foregroundStyle(Color(uiColor: theme.text))
                        .font(Font(WMFFont.for(.callout)))
                        .lineLimit(2)

                    if index < categories.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: theme.baseBackground), lineWidth: 0.5)
        )
    }
}
