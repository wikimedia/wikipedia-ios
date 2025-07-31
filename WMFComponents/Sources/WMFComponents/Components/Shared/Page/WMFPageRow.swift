import SwiftUI

/// A reusable component for displaying a page row (typically an article) with optional swipe actions. These should be embedded inside of a List.
struct WMFPageRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let id: String
    let titleHtml: String
    let articleDescription: String?
    let imageURLString: String?
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

    @State private var globalFrame: CGRect = .zero
    @State private var uiImage: UIImage?

    var rowContent: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleHtml)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(theme.text))

                if let description = articleDescription {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
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
        .task {
            if let imageURLString {
                self.uiImage = await loadImageAction(imageURLString)
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
