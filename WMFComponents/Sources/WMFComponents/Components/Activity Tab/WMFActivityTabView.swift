import SwiftUI
import WMFData
import Charts
import Foundation

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
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
                        
                        if !viewModel.model.topCategories.isEmpty {
                            topCategoriesModule(categories: viewModel.model.topCategories)
                        }
                    }
                    .padding(16)
                    .listRowInsets(EdgeInsets()) // removes default List padding
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
                    .padding(.horizontal, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: theme.paperBackground))
            .listStyle(.grouped)
            .onAppear {
                viewModel.fetchData()
                viewModel.hasSeenActivityTab()
            }
            .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        } else {
            loggedOutView
        }
    }
    
    private func getPreviewViewModel(from item: TimelineItem) -> WMFArticlePreviewViewModel {
        let summary = viewModel.model.pageSummaries[item.id]
        
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
            if let timeline = viewModel.model.timeline, !timeline.isEmpty {
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
            ForEach(sortedPages, id: \.id) { page in
                pageRow(page: page, section: date)
                    .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let pageToDelete = sortedPages[index]
                    viewModel.deletePage(item: pageToDelete)
                }
            }
        }
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

        let summary = viewModel.model.pageSummaries[page.id]
        let initialThumbnailURLString = summary?.thumbnailURL?.absoluteString ?? page.imageURLString

        return WMFPageRow(
            needsLimitedFontSize: false,
            id: page.id,
            titleHtml: page.pageTitle.replacingOccurrences(of: "_", with: " "),
            articleDescription: summary?.description ?? page.description,
            imageURLString: initialThumbnailURLString,
            titleLineLimit: 1,
            isSaved: false,
            showsSwipeActions: true,
            deleteItemAction: { viewModel.deletePage(item: page) },
            loadImageAction: { imageURLString in
                try? await viewModel.loadImage(imageURLString: imageURLString)
            },
            iconImage: iconImage
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onTap(page)
        }
        .contextMenu {
            Button {
                viewModel.onTap(page)
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
            if let fetchedSummary = await viewModel.fetchSummary(for: page) {
//                if fetchedSummary.thumbnailURL != nil {
//                    // Automatically updates
//                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(viewModel.model.usernamesReading)
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
    
    private var articlesReadModule: some View {
        Group {
            WMFActivityTabInfoCardView(
                icon: WMFSFSymbolIcon.for(symbol: .bookPages, font: WMFFont.boldCaption1),
                title: viewModel.localizedStrings.totalArticlesRead,
                dateText: viewModel.model.dateTimeLastRead,
                amount: viewModel.model.totalArticlesRead,
                onTapModule: {
                    print("Tapped module")
                    // TODO: Navigate to history below
                },
                content: {
                    articlesReadGraph(weeklyReads: viewModel.model.weeklyReads)
                }
            )
        }
    }
    
    private var savedArticlesModule: some View {
        Group {
            WMFActivityTabInfoCardView(
                icon: WMFSFSymbolIcon.for(symbol: .bookmark, font: WMFFont.boldCaption1),
                title: viewModel.localizedStrings.articlesSavedTitle,
                dateText: viewModel.model.dateTimeLastSaved,
                amount: viewModel.model.articlesSavedAmount,
                onTapModule: {
                    viewModel.navigateToSaved?()
                },
                content: {
                    if !viewModel.model.articlesSavedImages.isEmpty {
                        savedArticlesImages(images: viewModel.model.articlesSavedImages, totalSavedCount: viewModel.model.articlesSavedAmount)
                    }
                }
            )
        }
    }
    
    private func savedArticlesImages(images: [URL], totalSavedCount: Int) -> some View {
        HStack(spacing: 4) {
            if images.count <= 4 {
                ForEach(images.prefix(4), id: \.self) { imageURL in
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
            } else {
                ForEach(images.prefix(3), id: \.self) { imageURL in
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

                let remaining = totalSavedCount - 3
                Text(viewModel.localizedStrings.remaining(remaining))
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
            }
        }
    }

    private func articlesReadGraph(weeklyReads: [Int]) -> some View {
        Group {
            Chart {
                ForEach(weeklyReads.indices, id: \.self) { index in
                    BarMark(
                        x: .value(viewModel.localizedStrings.week, index),
                        y: .value(viewModel.localizedStrings.articlesRead, weeklyReads[index] + 1),
                        width: 12
                    )
                    .foregroundStyle(weeklyReads[index] > 0 ? Color(uiColor: theme.accent) : Color(uiColor: theme.newBorder))
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
