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

struct RabbitHoleInfographicView: View {

    let articles: [RabbitHoleArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("My Wikipedia Rabbit Hole")
                .font(.largeTitle.weight(.bold))

            ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                RabbitHoleArticleCard(
                    index: index,
                    article: article
                )
            }

            Text("Generated from Wikipedia")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 24)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}


struct RabbitHoleArticleCard: View {

    let index: Int
    let article: RabbitHoleArticle

    @State private var showImages = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("\(index + 1)")
                            .foregroundColor(.white)
                            .font(.headline)
                    )

                Text(article.title)
                    .font(.title3.weight(.semibold))
            }

            if !article.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(article.images.enumerated()), id: \.offset) { idx, url in
                            RabbitHoleImageView(url: url)
                                .frame(width: 180, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .opacity(showImages ? 1 : 0)
                                .offset(y: showImages ? 0 : 12)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(idx) * 0.08),
                                    value: showImages
                                )
                        }
                    }
                    .padding(.leading, 48)
                }
            }
        }
        .onAppear {
            showImages = true
        }
    }
}

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
