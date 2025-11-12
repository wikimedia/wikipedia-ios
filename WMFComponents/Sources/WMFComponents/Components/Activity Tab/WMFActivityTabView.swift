import SwiftUI
import Charts

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }
    
    @State private var articles: [TimelineItem] = [
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Roman_Empire"),
            titleHtml: "The History of the Roman Empire",
            description: "A deep dive into the rise, expansion, and legacy of the Roman Empire.",
            shortDescription: "Explore the rise and fall of Rome.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "The Roman Empire was one of the most influential civilizations in world history.",
            variant: "history"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Quantum_computing"),
            titleHtml: "How Quantum Computing Works",
            description: "An introduction to qubits, superposition, and the future of computation.",
            shortDescription: "The power of quantum bits.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "Quantum computing uses the principles of quantum mechanics to perform calculations.",
            variant: "technology"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Black_hole"),
            titleHtml: "10 Fascinating Facts About Black Holes",
            description: "Discover the mysteries behind one of the universe’s most extreme phenomena.",
            shortDescription: "Exploring the mysteries of black holes.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "Black holes warp spacetime so strongly that nothing, not even light, can escape.",
            variant: "science"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Japanese_calligraphy"),
            titleHtml: "The Art of Japanese Calligraphy",
            description: "An elegant look into the brush strokes and philosophy of Shodo.",
            shortDescription: "Beauty in brush and ink.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "Japanese calligraphy, or Shodo, is both a visual art and a spiritual discipline.",
            variant: "art"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Climate_change"),
            titleHtml: "Climate Change: What We Can Still Do",
            description: "Examining current climate trends and actionable solutions for the planet.",
            shortDescription: "Hope in climate action.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "Human activity continues to drive global warming, but mitigation is still possible.",
            variant: "environment"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Ancient_civilization"),
            titleHtml: "The Rise and Fall of Ancient Civilizations",
            description: "A look at the forces that built — and destroyed — ancient societies.",
            shortDescription: "Lessons from the past.",
            imageURLString: "https://commons.wikimedia.org/wiki/File:Polar_Bear_AdF.jpg",
            isSaved: false,
            snippet: "Ancient civilizations like Egypt and Mesopotamia laid the foundations for modern culture.",
            variant: "history"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Deep_sea_ecosystem"),
            titleHtml: "Exploring Deep Sea Ecosystems",
            description: "Dive into the world of bioluminescent creatures and oceanic mysteries.",
            shortDescription: "Life in the darkest depths.",
            imageURLString: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Deep_sea_creature.jpg/320px-Deep_sea_creature.jpg",
            isSaved: false,
            snippet: "Despite the darkness, the deep sea teems with life adapted to extreme pressure.",
            variant: "nature"
        ),
        TimelineItem(
            id: UUID().uuidString,
            url: URL(string: "https://en.wikipedia.org/wiki/Artificial_intelligence"),
            titleHtml: "The Evolution of Artificial Intelligence",
            description: "Tracing AI’s growth from simple algorithms to deep learning systems.",
            shortDescription: "From logic to learning.",
            imageURLString: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Artificial_Intelligence_%26_Machine_Learning.png/320px-Artificial_Intelligence_%26_Machine_Learning.png",
            isSaved: true,
            snippet: "Artificial intelligence is reshaping industries, creativity, and human interaction.",
            variant: "technology"
        )
    ]

    @State private var selectedArticle: TimelineItem? = nil
    @State private var showPreview = false
    
    private func getPreviewViewModel(from item: TimelineItem) -> WMFArticlePreviewViewModel {
        return WMFArticlePreviewViewModel(url: item.url, titleHtml: item.titleHtml, description: item.description, imageURLString: item.imageURLString, isSaved: item.isSaved, snippet: item.snippet)
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
                
                // MARK: - History Section
                Section(header: Text("Articles")
                    .font(.headline)
                    .foregroundColor(Color(uiColor: theme.text))
                ) {
                    ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                        Text(article.titleHtml)
                            .foregroundColor(Color(uiColor: theme.link))
                            .padding(.vertical, 4)
                            .contextMenu {
                                Button {
                                    print("open article action")
                                    // viewModel.onTap(article)
                                } label: {
                                    Text("open article")
                                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
                                }
                                .labelStyle(.titleAndIcon)
                            } preview: {
                                WMFArticlePreviewView(viewModel: getPreviewViewModel(from: article))
                            }
                    }
                    .onDelete { indexSet in
                        articles.remove(atOffsets: indexSet)
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                viewModel.fetchData()
                viewModel.hasSeenActivityTab()
            }
            .background(Color(uiColor: theme.paperBackground).edgesIgnoringSafeArea(.all))
        } else {
            loggedOutView
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


private final class TimelineItem: Identifiable, Equatable {
    public let id: String
    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let shortDescription: String?
    public let imageURLString: String?
    public var isSaved: Bool
    public let snippet: String?
    public let variant: String?

    public init(id: String, url: URL?, titleHtml: String, description: String?, shortDescription: String?, imageURLString: String?, isSaved: Bool, snippet: String?, variant: String?) {
        self.id = id
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        self.shortDescription = shortDescription
        self.imageURLString = imageURLString
        self.isSaved = isSaved
        self.snippet = snippet
        self.variant = variant
    }

    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        return lhs.id == rhs.id
    }
}
