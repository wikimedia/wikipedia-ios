import SwiftUI

public struct WMFRabbitHoleView: View {
    @ObservedObject var viewModel: WMFRabbitHoleViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: WMFRabbitHoleViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding your rabbit hole...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.articles.enumerated()), id: \.1.title) { index, article in
                                RabbitHoleArticleRow(
                                    article: article,
                                    stepNumber: index + 1,
                                    isLast: index == viewModel.articles.count - 1
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("🐰 Rabbit Hole")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RabbitHoleArticleRow: View {
    let article: RabbitHoleArticle
    let stepNumber: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator with connecting line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isLast ? Color.yellow : Color.blue)
                        .frame(width: 32, height: 32)
                    
                    if isLast {
                        Text("🏆")
                            .font(.system(size: 16))
                    } else {
                        Text("\(stepNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Article card
            HStack(spacing: 12) {
                // Thumbnail
                if let imageURL = article.images.first {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                        )
                }
                
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if isLast {
                        Text("Destination")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isLast ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .padding(.bottom, isLast ? 0 : 8)
    }
}

struct RabbitHoleArticle: Identifiable {
    let id = UUID()
    let title: String
    let images: [URL]
}
