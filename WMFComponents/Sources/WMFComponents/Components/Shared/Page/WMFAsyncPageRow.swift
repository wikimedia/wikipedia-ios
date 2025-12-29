import SwiftUI
import WMFData

final class WMFAsyncPageRowViewModel: ObservableObject {
    
    let id: String
    let title: String
    let projectID: String
    let iconImage: UIImage?
    let iconAccessibilityLabel: String
    
    let tapAction: (() -> Void)?
    let contextMenuOpenAction: (() -> Void)?
    let contextMenuOpenText: String?
    
    let deleteItemAction: (() -> Void)?
    let deleteAccessibilityLabel: String?
    
    private var summary: WMFArticleSummary?
    @Published var articleDescription: String?
    @Published var uiImage: UIImage?
    
    internal init(id: String, title: String, projectID: String, iconImage: UIImage? = nil, iconAccessibilityLabel: String, tapAction: (() -> Void)? = nil, contextMenuOpenAction: (() -> Void)? = nil, contextMenuOpenText: String? = nil, deleteItemAction: (() -> Void)? = nil, deleteAccessibilityLabel: String? = nil) {
        self.id = id
        self.title = title
        self.projectID = projectID
        self.iconImage = iconImage
        self.iconAccessibilityLabel = iconAccessibilityLabel
        self.articleDescription = nil
        self.uiImage = nil
        self.tapAction = tapAction
        self.contextMenuOpenAction = contextMenuOpenAction
        self.contextMenuOpenText = contextMenuOpenText
        self.deleteItemAction = deleteItemAction
        self.deleteAccessibilityLabel = deleteAccessibilityLabel
        self.summary = nil
        
        Task {
            try await loadDescriptionAndImage()
        }
        
    }
    
    @MainActor
    private func loadDescriptionAndImage() async throws {
        
        let summaryDataController = WMFArticleSummaryDataController.shared
        
        guard let project = WMFProject(id: projectID) else {
            return
        }
        
        let summary = try? await summaryDataController.fetchArticleSummary(project: project, title: title)
        
        self.summary = summary
        
        if let desc = summary?.description, !desc.isEmpty {
            self.articleDescription = desc
        } else if let extract = summary?.extract, !extract.isEmpty {
            self.articleDescription = extract
        } else {
            self.articleDescription = nil
        }
        
        let imageDataController = WMFImageDataController()
        
        guard let thumbnailURL = summary?.thumbnailURL else {
            return
        }
        let data = try await imageDataController.fetchImageData(url: thumbnailURL)
        
        self.uiImage = UIImage(data: data)
    }
    
    func previewViewModel() -> WMFArticlePreviewViewModel? {
        guard let summary = self.summary else {
            return nil
        }
        
        return WMFArticlePreviewViewModel(titleHtml: self.title, description: self.articleDescription, image: self.uiImage, backgroundImage: nil, isSaved: false, snippet: summary.extract)
    }
    
    var accessibilityLabelParts: String {
        [iconAccessibilityLabel, title, articleDescription].compactMap { $0 }.joined(separator: " - ")
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
                    .frame(width: 40, height: 40, alignment: .top)
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
        .padding(.vertical, 10)
    }

    @ViewBuilder
    var regularTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .font(WMFSwiftUIFont.font(.callout))
                .foregroundColor(Color(theme.text))
                .lineLimit(1)
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
        .listRowSeparator(.hidden)
        .accessibilityElement()
        .accessibilityLabel(viewModel.accessibilityLabelParts)
        .accessibilityAddTraits(.isButton)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.tapAction?()
        }
        .swipeActions {
            if let deleteItemAction = viewModel.deleteItemAction {
                Button {
                    withAnimation(.default) {
                        deleteItemAction()
                    }
                } label: {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .trash) ?? UIImage())
                        .accessibilityLabel(viewModel.deleteAccessibilityLabel ?? "")
                }
                .tint(Color(theme.destructive))
                .labelStyle(.iconOnly)
            }
        }
        .contextMenu {
            if let openAction = viewModel.contextMenuOpenAction,
               let openText = viewModel.contextMenuOpenText {
                Button {
                    openAction()
                } label: {
                    HStack {
                        Text(openText)
                            .font(Font(WMFFont.for(.mediumSubheadline)))
                        Spacer()
                        if let icon = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline) {
                            Image(uiImage: icon)
                        }
                    }
                }
            }
        } preview: {
            if let previewViewModel = viewModel.previewViewModel() {
                WMFArticlePreviewView(viewModel: previewViewModel)
            }
        }
        
    }
}
