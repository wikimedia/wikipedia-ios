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
            RabbitHolePathView(articles: articles)
        }
    }
}

// MARK: - Path View (Zig-Zag Layout with Curves)

struct RabbitHolePathView: View {

    let articles: [RabbitHoleArticle]
    @State private var pathProgress: CGFloat = 0
    
    func bubbleSize(for index: Int) -> CGFloat {
        let count = articles.count
        if index == 0 || index == count - 1 {
            // First and last are biggest (but smaller overall)
            return CGFloat.random(in: 120...150)
        } else {
            // Middle bubbles are smaller
            return CGFloat.random(in: 80...110)
        }
    }
    
    func bubbleDelay(for index: Int) -> Double {
        // Calculate delay based on path progress
        // The line takes 2 seconds, so space out bubbles proportionally
        let totalDuration = 2.0
        let proportion = Double(index) / Double(max(articles.count - 1, 1))
        return totalDuration * proportion
    }

    var body: some View {
        ZStack {
            // Draw the curvy path behind the bubbles with tracing animation and gradient width
            CurvedPathShape(articleCount: articles.count)
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
                    withAnimation(.easeInOut(duration: 2.0)) {
                        pathProgress = 1.0
                    }
                }
            
            // Draw the bubbles on top with staggered animation
            VStack(spacing: 60) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { idx, article in
                    HStack {
                        if idx % 2 == 0 {
                            Spacer()
                            RabbitHoleBubble(article: article, size: bubbleSize(for: idx), delay: bubbleDelay(for: idx))
                        } else {
                            RabbitHoleBubble(article: article, size: bubbleSize(for: idx), delay: bubbleDelay(for: idx))
                            Spacer()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var overlay: some View {
        CurvedPathShape(articleCount: articles.count)
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
                
                // Calculate curve intensity based on position
                // Bigger curves at start and end, smaller in middle
                let totalSegments = points.count - 1
                let normalizedPosition = CGFloat(i) / CGFloat(totalSegments)
                
                // Create a curve that's bigger at 0 and 1, smaller at 0.5
                let curveIntensity: CGFloat
                if normalizedPosition < 0.5 {
                    // First half: decrease from 50 to 20
                    curveIntensity = 50 - (normalizedPosition * 2 * 30)
                } else {
                    // Second half: increase from 20 to 50
                    curveIntensity = 20 + ((normalizedPosition - 0.5) * 2 * 30)
                }
                
                // Create an S-curve by using two control points
                let controlPoint1 = CGPoint(
                    x: previousPoint.x,
                    y: midY - curveIntensity
                )
                
                let controlPoint2 = CGPoint(
                    x: currentPoint.x,
                    y: midY + curveIntensity
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
    let delay: Double
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 8) {
            bubbleImage
            bubbleTitle
        }
        .scaleEffect(isVisible ? 1 : 0.3)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: size)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
    
    private var bubbleImage: some View {
        Group {
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
        }
    }
    
    private var bubbleTitle: some View {
        VStack(spacing: 2) {
            Text(article.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: size)
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
