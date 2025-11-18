import SwiftUI
import WMFData

final class WMFAsyncPageRowViewModel: ObservableObject {
    
    let wmfPage: WMFPage
    let id: String
    let titleHtml: String
    let imageURLString: String?
    let iconImage: UIImage?
    
    @Published var articleDescription: String?
    @Published var uiImage: UIImage?
    
    internal init(wmfpage: WMFPage, id: String, titleHtml: String, imageURLString: String? = nil, iconImage: UIImage? = nil, articleDescription: String? = nil, uiImage: UIImage? = nil) {
        self.wmfPage = wmfpage
        self.id = id
        self.titleHtml = titleHtml
        self.imageURLString = imageURLString
        self.iconImage = iconImage
        self.articleDescription = articleDescription
        self.uiImage = uiImage
    }
    
    @MainActor
    public func loadDescriptionAndImage() async throws {
        
        let summaryDataController = WMFArticleSummaryDataController.shared
        
        guard let project = WMFProject(id: wmfPage.projectID) else {
            return
        }
        
        let summary = try? await summaryDataController.fetchArticleSummary(project: project, title: wmfPage.title)
        self.articleDescription = summary?.description
        
        let imageDataController = WMFImageDataController()
        
        guard let thumbnailURL = summary?.thumbnailURL else {
            return
        }
        let data = try await imageDataController.fetchImageData(url: thumbnailURL)
        
        self.uiImage = UIImage(data: data)
        
    }
    
    public func loadImage(imageURLString: String?) async throws {
        let imageDataController = WMFImageDataController()
        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return
        }
        let data = try await imageDataController.fetchImageData(url: url)
        self.uiImage = UIImage(data: data)
    }
}

/// A reusable component for displaying a page row (typically an article). This component is capable of fetching and updating the article description label and thumbnail image internally. These should be embedded inside of a List.
struct WMFAsyncPageRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFAsyncPageRowViewModel
    
    init (viewModel: WMFAsyncPageRowViewModel) {
        self.viewModel = viewModel
    }

    var rowContent: some View {
        HStack(alignment: .top, spacing: 4) {
            if let iconImage = viewModel.iconImage {
                Image(uiImage: iconImage)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }
            regularTextView
            Spacer()
            if let uiImage = viewModel.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

            }
        }
        .background(Color(theme.paperBackground))
        .padding(.vertical, 8)
        .onAppear {
            Task {
                try? await viewModel.loadDescriptionAndImage()
            }
        }
    }

    @ViewBuilder
    var regularTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.titleHtml)
                .font(WMFSwiftUIFont.font(.callout))
                .foregroundColor(Color(theme.text))
            if let description = viewModel.articleDescription {
                Text(description)
                    .font(WMFSwiftUIFont.font(.subheadline))
                    .foregroundColor(Color(theme.secondaryText))
                    .lineLimit(1)
            }
        }
    }

    var body: some View {
        rowContent
    }
}
