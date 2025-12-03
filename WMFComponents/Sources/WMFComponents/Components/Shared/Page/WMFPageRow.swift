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
        HStack(alignment: .top, spacing: 12) {
            if let iconImage {
                Image(uiImage: iconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }

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
            
            Spacer()
            
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Spacer()
            }
        }
        .padding(0)
        .frame(maxWidth: .infinity, alignment: .leading)

        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(theme.paperBackground))
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
