import SwiftUI
import WMFData

/// A reusable component for displaying a page row (typically an article) with optional swipe actions. These should be embedded inside of a List.
struct WMFPageRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let needsLimitedFontSize: Bool
    let id: String
    let titleHtml: String
    let articleDescription: String?
    let imageURLString: String?
    let titleLineLimit: Int
    let isSaved: Bool
    let deleteAccessibilityLabel: String?
    let shareAccessibilityLabel: String?
    let saveAccessibilityLabel: String?
    let unsaveAccessibilityLabel: String?
    let showsSwipeActions: Bool
    let deleteItemAction: (() -> Void)?
    let shareItemAction: ((CGRect?) -> Void)?
    let saveOrUnsaveItemAction: (() -> Void)?
    let loadImageAction: (String?) async -> UIImage?

    init(appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, needsLimitedFontSize: Bool, id: String, titleHtml: String, articleDescription: String?, imageURLString: String?, titleLineLimit: Int, isSaved: Bool = false, deleteAccessibilityLabel: String? = nil, shareAccessibilityLabel: String? = nil, saveAccessibilityLabel: String? = nil, unsaveAccessibilityLabel: String? = nil, showsSwipeActions: Bool, deleteItemAction: (() -> Void)? = nil, shareItemAction: ((CGRect?) -> Void)? = nil, saveOrUnsaveItemAction: (() -> Void)? = nil, loadImageAction: @escaping (String?) async -> UIImage?, uiImage: UIImage? = nil, iconImage: UIImage? = nil) {
        self.appEnvironment = appEnvironment
        self.needsLimitedFontSize = needsLimitedFontSize
        self.id = id
        self.titleHtml = titleHtml
        self.articleDescription = articleDescription
        self.imageURLString = imageURLString
        self.titleLineLimit = titleLineLimit
        self.isSaved = isSaved
        self.deleteAccessibilityLabel = deleteAccessibilityLabel
        self.shareAccessibilityLabel = shareAccessibilityLabel
        self.saveAccessibilityLabel = saveAccessibilityLabel
        self.unsaveAccessibilityLabel = unsaveAccessibilityLabel
        self.showsSwipeActions = showsSwipeActions
        self.deleteItemAction = deleteItemAction
        self.shareItemAction = shareItemAction
        self.saveOrUnsaveItemAction = saveOrUnsaveItemAction
        self.loadImageAction = loadImageAction
        self.uiImage = uiImage
        self.iconImage = iconImage
    }

    @State private var globalFrame: CGRect = .zero
    @State private var uiImage: UIImage?
    var iconImage: UIImage?

    var rowContent: some View {
        HStack(alignment: .top, spacing: 4) {
            if let iconImage {
                Image(uiImage: iconImage)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }
            if needsLimitedFontSize {
                textViewLimitedFontSize
            } else {
                regularTextView
            }
            Spacer()
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

            }
        }
        .background(Color(theme.paperBackground))
        .padding(.vertical, 8)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        globalFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { newValue in
                        globalFrame = newValue
                    }
            }
        )
        .task(id: imageURLString) {
            if let imageURLString {
                self.uiImage = await loadImageAction(imageURLString)
            } else {
                self.uiImage = nil
            }
        }
    }
    
    @ViewBuilder
    var textViewLimitedFontSize: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleHtml)
                .font(WMFSwiftUIFont.font(.callout))
                .foregroundColor(Color(theme.text))
                .lineLimit(titleLineLimit)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            if let description = articleDescription {
                Text(description)
                    .font(WMFSwiftUIFont.font(.subheadline))
                    .foregroundColor(Color(theme.secondaryText))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var regularTextView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleHtml)
                .font(WMFSwiftUIFont.font(.callout))
                .foregroundColor(Color(theme.text))
                .lineLimit(titleLineLimit)
            if let description = articleDescription {
                Text(description)
                    .font(WMFSwiftUIFont.font(.subheadline))
                    .foregroundColor(Color(theme.secondaryText))
                    .lineLimit(1)
            }
        }
    }

    var body: some View {
        if showsSwipeActions {
            rowContent
                .swipeActions {
                    if let deleteItemAction {
                        Button {
                            withAnimation(.default) {
                                deleteItemAction()
                            }
                        } label: {
                            Image(uiImage: WMFSFSymbolIcon.for(symbol: .trash) ?? UIImage())
                                .accessibilityLabel(deleteAccessibilityLabel ?? "")
                        }
                        .tint(Color(theme.destructive))
                        .labelStyle(.iconOnly)
                    }

                    if let shareItemAction {
                        Button {
                            shareItemAction(globalFrame)
                        } label: {
                            Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                                .accessibilityLabel(shareAccessibilityLabel ?? "")
                        }
                        .tint(Color(theme.secondaryAction))
                        .labelStyle(.iconOnly)
                    }

                    if let saveOrUnsaveItemAction {
                        Button {
                            saveOrUnsaveItemAction()
                        } label: {
                            let symbol: WMFSFSymbolIcon = isSaved ? .bookmarkFill : .bookmark
                            let label = isSaved ? saveAccessibilityLabel : unsaveAccessibilityLabel
                            Image(uiImage: WMFSFSymbolIcon.for(symbol: symbol) ?? UIImage())
                                .accessibilityLabel(label ?? "")
                        }
                        .tint(Color(theme.link))
                        .labelStyle(.iconOnly)
                    }
                }
        } else {
            rowContent
        }
    }
}

// MARK: - BEGIN: WMFNEWPAGEROW

final class WMFNewPageRowViewModel: ObservableObject {
    
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
        
        let summaryDataController = WMFArticleSummaryDataController()
        
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

/// A reusable component for displaying a page row (typically an article) with optional swipe actions. These should be embedded inside of a List.
struct WMFNewPageRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFNewPageRowViewModel
    
    init (viewModel: WMFNewPageRowViewModel) {
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
        .task(id: viewModel.imageURLString) {
            try? await viewModel.loadDescriptionAndImage()
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

// MARK: - END: WMFNEWPAGEROW
