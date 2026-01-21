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

// MARK: - Path View (Zig-Zag Layout)

struct RabbitHolePathView: View {

    let articles: [RabbitHoleArticle]

    var body: some View {
        VStack(spacing: 60) {
            ForEach(Array(articles.enumerated()), id: \.element.id) { idx, article in
                HStack {
                    if idx % 2 == 0 {
                        Spacer()
                        RabbitHoleBubble(article: article, size: CGFloat.random(in: 120...180))
                    } else {
                        RabbitHoleBubble(article: article, size: CGFloat.random(in: 120...180))
                        Spacer()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 32)
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
