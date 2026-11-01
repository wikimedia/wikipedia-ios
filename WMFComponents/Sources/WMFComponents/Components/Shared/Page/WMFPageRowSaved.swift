import SwiftUI
import WMFData
import WMFNativeLocalizations

struct WMFPageRowSavedAlertView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFPageRowSavedViewModel

    private var alertString: String? {
        switch viewModel.alertType {
        case .listLimitExceeded:
            return CommonStrings.readingListsErrorListLimitExceeded
        case .entryLimitExceeded:
            return CommonStrings.readingListsErrorArticleLimitExceeded
        case .genericNotSynced:
            return CommonStrings.readingListsErrorNotSynced
        case .downloading:
            return CommonStrings.readingListsWarningArticleQueuedToBeDownloaded
        case .articleError(let errorDescription):
            return errorDescription
        case .none:
            return nil
        }
    }

    var body: some View {
            if let alertString = alertString {
                Button {
                    viewModel.didTapAlert?()
                } label: {
                    HStack(spacing: 4) {
                        if let icon = WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangle, font: .semiboldCaption1) {
                            Image(uiImage: icon)
                        }
                        Text(alertString)
                            .font(Font(WMFFont.for(.semiboldCaption1)))
                    }
                    .foregroundColor(Color(uiColor: appEnvironment.theme.warning))
                }
                .buttonStyle(.plain)
            }
        }
}

struct WMFPageRowSaved: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFPageRowSavedViewModel

    typealias FromLongPress = Bool
    let onTap: (FromLongPress) -> Void
    let onDelete: (FromLongPress) -> Void
    let onShare: (CGRect, FromLongPress) -> Void
    let onOpenInNewTab: () -> Void
    let onOpenInBackgroundTab: () -> Void

    var body: some View {
        Button(action: {
            self.onTap(false)
        }) {
            HStack(spacing: WMFSpacing.medium) {
                if viewModel.isEditing {
                    selectionIndicator
                }

                HStack(spacing: WMFSpacing.medium) {

                    VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
                        Text(viewModel.title)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundColor(Color(uiColor: appEnvironment.theme.text))
                            .lineLimit(1)


                        Text(viewModel.description ?? " ")
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                            .lineLimit(1)

                        Spacer()


                        if viewModel.isAlertHidden {
                            if !viewModel.readingListNames.isEmpty {
                                readingListTags
                            }
                        } else {
                            WMFPageRowSavedAlertView(viewModel: viewModel)
                        }

                    }

                    Spacer()

                    thumbnailView
                }
                .environment(\.layoutDirection, viewModel.project.isRTL ? .rightToLeft : .leftToRight)
            }
            .padding(.horizontal, WMFSpacing.large)
            .padding(.vertical, WMFSpacing.medium)
            .frame(minHeight: 124, alignment: .leading)
        }
        .accessibilityElement()
        .accessibilityLabel("\(viewModel.title) - \(viewModel.description ?? "")")
        .accessibilityAddTraits(.isButton)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewModel.geometryFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        viewModel.geometryFrame = geometry.frame(in: .global)
                    }
            }
            .allowsHitTesting(false)
        )
        .contextMenu {
            Button {
                onTap(true)
            } label: {
                Text(CommonStrings.articleTabsOpen)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button {
                onDelete(true)
            } label: {
                Text(CommonStrings.unsaveTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .bookmark) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button {
                onOpenInNewTab()
            } label: {
                Text(CommonStrings.articleTabsOpenInNewTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button {
                onOpenInBackgroundTab()
            } label: {
                Text(CommonStrings.articleTabsOpenInBackgroundTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button {
                onShare(viewModel.geometryFrame, true)
            } label: {
                Text(CommonStrings.shortShareTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

        } preview: {
            WMFArticlePreviewView(viewModel: getPreviewViewModel(from:viewModel))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {

            if !viewModel.isEditing {

                if let shareIcon = WMFIcon.share,
                   let deleteIcon = WMFIcon.delete {
                    Button(action: {
                        onDelete(false)
                    }) {
                        Image(uiImage: deleteIcon)
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Saved.rowDeleteSwipeButton)
                    .tint(Color(uiColor: appEnvironment.theme.destructive))

                    Button(action: {
                        onShare(viewModel.geometryFrame, false)
                    }) {
                        Image(uiImage: shareIcon)
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Saved.rowShareSwipeButton)
                    .tint(Color(uiColor: appEnvironment.theme.secondaryAction))
                }
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        switch viewModel.imageLoadingState {
        case .loading:
            Color(uiColor: appEnvironment.theme.midBackground)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        case .loaded:
            if let uiImage = viewModel.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        case .noImage:
            EmptyView()
        }
    }

    private var selectionIndicator: some View {
        Image(systemName: viewModel.isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(viewModel.isSelected ? Color(uiColor: appEnvironment.theme.link) : Color(uiColor: appEnvironment.theme.secondaryText))
            .font(.system(size: 22))
    }

    private var readingListTags: some View {
        let names = viewModel.readingListNames

        return ViewThatFits(in: .horizontal) {
            // Try all tags
            if names.count >= 1 {
                HStack(spacing: 4) {
                    ForEach(names, id: \.self) { name in
                        tagView(listName: name, overflowCount: nil)
                    }
                }
            }

            // Try all but one + overflow
            if names.count >= 2 {
                HStack(spacing: 4) {
                    ForEach(names.dropLast(1), id: \.self) { name in
                        tagView(listName: name, overflowCount: nil)
                    }
                    tagView(listName: nil, overflowCount: 1)
                }
            }

            // Try all but two + overflow
            if names.count >= 3 {
                HStack(spacing: 4) {
                    ForEach(names.dropLast(2), id: \.self) { name in
                        tagView(listName: name, overflowCount: nil)
                    }
                    tagView(listName: nil, overflowCount: 2)
                }
            }

            // Try first two + overflow
            if names.count >= 3 {
                HStack(spacing: 4) {
                    tagView(listName: names[0], overflowCount: nil)
                    tagView(listName: names[1], overflowCount: nil)
                    tagView(listName: nil, overflowCount: names.count - 2)
                }
            }

            // Try first one + overflow
            if names.count >= 2 {
                HStack(spacing: 4) {
                    tagView(listName: names[0], overflowCount: nil)
                    tagView(listName: nil, overflowCount: names.count - 1)
                }
            }

            // Fallback: just overflow
            if names.count >= 1 {
                tagView(listName: nil, overflowCount: names.count)
            }
        }
    }

    private func tagView(listName: String?, overflowCount: Int?) -> some View {
        var text: String? = nil
        if let listName {
            text = listName
        } else if let overflowCount {
            text = "+\(overflowCount)"
        }

        return Group {
            if let text {
                Button {
                        viewModel.didTapReadingListTag?(listName)
                } label: {
                    Text(text)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundColor(Color(uiColor: appEnvironment.theme.tagText))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(uiColor: appEnvironment.theme.tagBackground))
                        .cornerRadius(4)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Saved.readingListTag(text))
            }
        }
    }

    private func getPreviewViewModel(from viewModel: WMFPageRowSavedViewModel) -> WMFArticlePreviewViewModel {
        var url: URL? = nil
        if let siteURL = viewModel.project.siteURL {
            var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
            components?.path = "/wiki/\(viewModel.title)"
            url = components?.url
        }

        return WMFArticlePreviewViewModel(url: url, titleHtml: viewModel.title, description: viewModel.description, imageURLString: viewModel.imageURL?.absoluteString, isSaved: true, snippet: viewModel.snippet)
    }
}
