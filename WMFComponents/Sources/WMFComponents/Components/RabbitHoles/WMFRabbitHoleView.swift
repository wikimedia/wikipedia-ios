import SwiftUI

public class WMFRabbitHoleHostingController: UIHostingController<WMFRabbitHoleView> {
    
    public init(viewModel: WMFRabbitHoleViewModel, view: WMFRabbitHoleView) {
        super.init(rootView: view)
        
        modalPresentationStyle = .pageSheet
        
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        hidesBottomBarWhenPushed = true
    }
    
    public override func viewDidLoad() {
        title = "🐰 Rabbit Hole"
        super.viewDidLoad()
        
        navigationController?.hidesBarsOnSwipe = false
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Model

@MainActor
public class WMFRabbitHoleViewModel: ObservableObject {
    @Published public var articles: [RabbitHoleArticle] = []
    @Published public var isLoading = true
    
    private let urls: [URL]
    public var onArticleTapped: ((_ tappedURL: URL, _ remainingURLs: [URL]) -> Void)?
    
    public init(urls: [URL], onArticleTapped: ((_ tappedURL: URL, _ remainingURLs: [URL]) -> Void)? = nil) {
        self.urls = urls
        self.onArticleTapped = onArticleTapped
        Task {
            await fetchArticles()
        }
    }
    
    private func fetchArticles() async {
        isLoading = true
        
        articles = await withTaskGroup(of: (Int, RabbitHoleArticle?).self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let article = await self.fetchPageSummary(for: url)
                    return (index, article)
                }
            }
            
            var results: [(Int, RabbitHoleArticle?)] = []
            for await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }
        
        isLoading = false
    }
    
    private func fetchPageSummary(for url: URL) async -> RabbitHoleArticle? {
        guard let title = url.wmf_title else {
            return nil
        }
        
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        let summaryURLString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(encodedTitle)"
        
        guard let summaryURL = URL(string: summaryURLString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: summaryURL)
            let summary = try JSONDecoder().decode(PageSummary.self, from: data)
            
            var images: [URL] = []
            if let thumbnail = summary.thumbnail?.source, let thumbnailURL = URL(string: thumbnail) {
                images.append(thumbnailURL)
            }
            
            let cleanTitle = summary.title.replacingOccurrences(of: "_", with: " ")
            
            return RabbitHoleArticle(
                title: cleanTitle,
                images: images,
                url: url
            )
        } catch {
            print("Error fetching summary for \(title): \(error)")
            return nil
        }
    }
    
    func articleTapped(at index: Int) {
        guard index < articles.count else { return }
        
        let tappedArticle = articles[index]
        let remainingArticles = Array(articles.dropFirst(index + 1))
        let remainingURLs = remainingArticles.map { $0.url }
        
        onArticleTapped?(tappedArticle.url, remainingURLs)
    }
}

private struct PageSummary: Codable {
    let title: String
    let displaytitle: String?
    let thumbnail: ImageInfo?
    
    struct ImageInfo: Codable {
        let source: String
    }
}

// MARK: - Article Model

public struct RabbitHoleArticle: Identifiable {
    public let id = UUID()
    public let title: String
    public let images: [URL]
    public let url: URL
    
    public init(title: String, images: [URL], url: URL) {
        self.title = title
        self.images = images
        self.url = url
    }
}

// MARK: - Main View

public struct WMFRabbitHoleView: View {

    @ObservedObject var viewModel: WMFRabbitHoleViewModel
    // @Environment(\.dismiss) private var dismiss

    public init(viewModel: WMFRabbitHoleViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Digging your rabbit hole...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        RabbitHoleInfographicView(
                            articles: viewModel.articles,
                            onArticleTapped: { index in
                                viewModel.articleTapped(at: index)
                            }
                        )
                        .padding()
                    }
                }
            }
            // .navigationTitle("🐰 Rabbit Hole")
            // .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
        }
    }
}

// MARK: - Infographic View

struct RabbitHoleInfographicView: View {

    let articles: [RabbitHoleArticle]
    let onArticleTapped: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            RabbitHolePathView(articles: articles, onArticleTapped: onArticleTapped)
        }
    }
}

// MARK: - Path View (Zig-Zag Layout with Curves)

struct RabbitHolePathView: View {

    let articles: [RabbitHoleArticle]
    let onArticleTapped: (Int) -> Void
    @State private var pathProgress: CGFloat = 0
    @State private var bubbleSizes: [CGFloat] = []
    @State private var borderWidths: [CGFloat] = []
    
    func initializeSizes() {
        guard bubbleSizes.isEmpty else { return }
        bubbleSizes = articles.indices.map { index in
            bubbleSize(for: index)
        }
        borderWidths = articles.indices.map { index in
            bubbleBorderWidth(for: index)
        }
    }
    
    func bubbleSize(for index: Int) -> CGFloat {
        let count = articles.count
        if index == 0 || index == count - 1 {
            return CGFloat.random(in: 80...120)
        } else {
            return CGFloat.random(in: 30...50)
        }
    }
    
    func bubbleBorderWidth(for index: Int) -> CGFloat {
        let count = articles.count
        if index == 0 || index == count - 1 {
            return CGFloat.random(in: 5...8)
        } else {
            return CGFloat.random(in: 2...4)
        }
    }
    
    func bubbleDelay(for index: Int) -> Double {
        let totalDuration = 2.0
        let proportion = Double(index) / Double(max(articles.count - 1, 1))
        return totalDuration * proportion
    }

    var body: some View {
        ZStack {
            CurvedPathShape(articleCount: articles.count, bubbleSizes: bubbleSizes)
                .trim(from: 0, to: pathProgress)
                .stroke(
                    Color.accentColor.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: 1,
                        lineCap: .round
                    )
                )
                .overlay(overlay)
                .onAppear {
                    initializeSizes()
                    withAnimation(.easeInOut(duration: 2.0)) {
                        pathProgress = 1.0
                    }
                }
            
            VStack(spacing: 25) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { idx, article in
                    HStack {
                        if idx % 2 == 0 {
                            Spacer()
                            if idx < bubbleSizes.count && idx < borderWidths.count {
                                RabbitHoleBubble(
                                    article: article,
                                    size: bubbleSizes[idx],
                                    borderWidth: borderWidths[idx],
                                    delay: bubbleDelay(for: idx),
                                    onTap: { onArticleTapped(idx) }
                                )
                            }
                        } else {
                            if idx < bubbleSizes.count && idx < borderWidths.count {
                                RabbitHoleBubble(
                                    article: article,
                                    size: bubbleSizes[idx],
                                    borderWidth: borderWidths[idx],
                                    delay: bubbleDelay(for: idx),
                                    onTap: { onArticleTapped(idx) }
                                )
                            }
                            Spacer()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            initializeSizes()
        }
    }
    
    private var overlay: some View {
        CurvedPathShape(articleCount: articles.count, bubbleSizes: bubbleSizes)
            .trim(from: 0, to: pathProgress)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.5),
                        Color.accentColor.opacity(0.35),
                        Color.accentColor.opacity(0.2),
                        Color.accentColor.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round
                )
            )
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white.opacity(0.8), location: 0.3),
                        .init(color: .white.opacity(0.4), location: 0.7),
                        .init(color: .white.opacity(0.1), location: 0.9),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

// MARK: - Curved Path Shape

struct CurvedPathShape: Shape {
    let articleCount: Int
    let bubbleSizes: [CGFloat]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard articleCount > 0 else { return path }
        
        let horizontalPadding: CGFloat = 32
        
        var points: [CGPoint] = []
        var currentY: CGFloat = 0
        let titleHeight: CGFloat = 35
        let titleSpacing: CGFloat = 4
        let betweenBubbleSpacing: CGFloat = 25
        
        for i in 0..<articleCount {
            let x: CGFloat
            let currentBubbleSize = i < bubbleSizes.count ? bubbleSizes[i] : 50
            
            if i % 2 == 0 {
                x = rect.width - horizontalPadding
            } else {
                x = horizontalPadding
            }
            
            // Center point should be at the middle of the bubble image only
            let centerY = currentY + (currentBubbleSize / 2)
            points.append(CGPoint(x: x, y: centerY))
            
            if i < articleCount - 1 {
                // Move to next bubble: current bubble + spacing below image + title height + spacing to next bubble
                currentY += currentBubbleSize + titleSpacing + titleHeight + betweenBubbleSpacing
            }
        }
        
        if points.count > 0 {
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let previousPoint = points[i - 1]
                let currentPoint = points[i]
                
                let distance = abs(currentPoint.y - previousPoint.y)
                
                let controlPoint1 = CGPoint(
                    x: previousPoint.x,
                    y: previousPoint.y + (distance * 0.3)
                )
                
                let controlPoint2 = CGPoint(
                    x: currentPoint.x,
                    y: currentPoint.y - (distance * 0.3)
                )
                
                path.addCurve(
                    to: currentPoint,
                    control1: controlPoint1,
                    control2: controlPoint2
                )
            }
        }
        
        return path
    }
}

// MARK: - Bubble View

struct RabbitHoleBubble: View {

    let article: RabbitHoleArticle
    let size: CGFloat
    let borderWidth: CGFloat
    let delay: Double
    let onTap: () -> Void
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 4) {
            bubbleImage
            
            // Floating title below the bubble with fixed height container
            Text(article.title)
                .font(.system(size: max(size * 0.14, 9), weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: size * 1.8)
                .frame(height: 35) // Fixed height for title area
        }
        .scaleEffect(isVisible ? 1 : 0.3)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: size)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var bubbleImage: some View {
        Group {
            if let imageURL = article.images.first {
                RabbitHoleImageView(url: imageURL)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: borderWidth)
                    )
                    .shadow(radius: 4)
            } else {
                Circle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: borderWidth)
                    )
            }
        }
    }
}

// MARK: - Image View

struct RabbitHoleImageView: View {

    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Color.red.opacity(0.2)
            case .empty:
                ProgressView()
            @unknown default:
                Color.secondary.opacity(0.2)
            }
        }
    }
}

// MARK: - URL Extension

private extension URL {
    var wmf_title: String? {
        guard let host = host,
              host.contains("wikipedia.org") else {
            return nil
        }
        
        let pathComponents = pathComponents
        
        guard let wikiIndex = pathComponents.firstIndex(of: "wiki"),
              wikiIndex + 1 < pathComponents.count else {
            return nil
        }
        
        let rawTitle = pathComponents[wikiIndex + 1]
        
        return rawTitle
            .removingPercentEncoding?
            .replacingOccurrences(of: "_", with: " ")
    }
}
