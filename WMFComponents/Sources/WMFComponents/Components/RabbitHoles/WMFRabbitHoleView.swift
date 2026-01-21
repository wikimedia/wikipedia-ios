import SwiftUI

public struct WMFRabbitHoleView: View {

    @ObservedObject var viewModel: WMFRabbitHoleViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: WMFRabbitHoleViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                RabbitHoleInfographicView(articles: viewModel.articles)
                    .padding()
            }
            .navigationTitle("Rabbit Hole")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
//                ToolbarItem(placement: .primaryAction) {
//                    ShareLink(
//                        item: Image(uiImage: viewModel.makeShareImage(size: CGSize(width: 1080, height: 1920))),
//                        preview: SharePreview(
//                            "My Wikipedia Rabbit Hole",
//                            image: Image(systemName: "doc.richtext")
//                        )
//                    )
//                }
            }
        }
    }
}

// MARK: - Infographic View

struct RabbitHoleInfographicView: View {

    let articles: [RabbitHoleArticle]

    var body: some View {
        VStack(spacing: 24) {
            Text("My Wikipedia Rabbit Hole")
                .font(.largeTitle.weight(.bold))
                .padding(.bottom, 16)

            RabbitHolePathView(articles: articles)

            Text("Generated from Wikipedia")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 24)
        }
    }
}

// MARK: - Path View (Zig-Zag Layout with Curves)

struct RabbitHolePathView: View {

    let articles: [RabbitHoleArticle]
    
    func bubbleSize(for index: Int) -> CGFloat {
        let count = articles.count
        if index == 0 || index == count - 1 {
            // First and last are biggest
            return CGFloat.random(in: 160...200)
        } else {
            // Middle bubbles are smaller
            return CGFloat.random(in: 100...140)
        }
    }

    var body: some View {
        ZStack {
            // Draw the curvy path behind the bubbles
            CurvedPathShape(articleCount: articles.count)
                .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            
            // Draw the bubbles on top
            VStack(spacing: 60) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { idx, article in
                    HStack {
                        if idx % 2 == 0 {
                            Spacer()
                            RabbitHoleBubble(article: article, size: bubbleSize(for: idx))
                        } else {
                            RabbitHoleBubble(article: article, size: bubbleSize(for: idx))
                            Spacer()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Curved Path Shape

struct CurvedPathShape: Shape {
    let articleCount: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard articleCount > 0 else { return path }
        
        let verticalSpacing: CGFloat = 60 + 180 // spacing + approximate bubble height
        let horizontalPadding: CGFloat = 32
        let availableWidth = rect.width - (horizontalPadding * 2)
        
        // Calculate positions for each bubble
        var points: [CGPoint] = []
        for i in 0..<articleCount {
            let y = CGFloat(i) * verticalSpacing
            let x: CGFloat
            
            if i % 2 == 0 {
                // Right side
                x = rect.width - horizontalPadding
            } else {
                // Left side
                x = horizontalPadding
            }
            
            points.append(CGPoint(x: x, y: y))
        }
        
        // Draw curved path through all points
        if points.count > 0 {
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let previousPoint = points[i - 1]
                let currentPoint = points[i]
                
                // Calculate control points for smooth curves
                let midY = (previousPoint.y + currentPoint.y) / 2
                
                // Create an S-curve by using two control points
                let controlPoint1 = CGPoint(
                    x: previousPoint.x,
                    y: midY - 30
                )
                
                let controlPoint2 = CGPoint(
                    x: currentPoint.x,
                    y: midY + 30
                )
                
                // Draw cubic Bezier curve
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

    var body: some View {
        VStack(spacing: 8) {
            if let imageURL = article.images.randomElement() {
                RabbitHoleImageView(url: imageURL)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            } else {
                Circle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: size, height: size)
            }

            VStack(spacing: 2) {
                Text(article.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
//                if let subtitle = article.subtitle {
//                    Text(subtitle)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(2)
//                }
            }
            .frame(maxWidth: size)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: size)
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
