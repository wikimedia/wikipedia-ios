import SwiftUI
import WMFData

struct WMFAsyncPageRowSavedAlertView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFAsyncPageRowSavedViewModel
    
    private var alertString: String? {
        switch viewModel.alertType {
        case .listLimitExceeded:
            return viewModel.localizedStrings.listLimitExceeded
        case .entryLimitExceeded:
            return viewModel.localizedStrings.entryLimitExceeded
        case .genericNotSynced:
            return viewModel.localizedStrings.notSynced
        case .downloading:
            return viewModel.localizedStrings.articleQueuedToBeDownloaded
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

struct WMFAsyncPageRowSaved: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFAsyncPageRowSavedViewModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: (CGRect) -> Void
    let onOpenInNewTab: () -> Void
    let onOpenInBackgroundTab: () -> Void

    private var maxReadableWidth: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 700
        case .xLarge, .xxLarge, .xxxLarge:
            return 800
        case .accessibility1, .accessibility2:
            return 900
        case .accessibility3, .accessibility4, .accessibility5:
            return .infinity // No limit for largest sizes
        @unknown default:
            return 700
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                
                HStack(spacing: 12) {
                    if viewModel.isEditing {
                        selectionIndicator
                    }
                    
                    HStack(spacing: 12) {

                        VStack(alignment: .leading, spacing: 4) {
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
                                WMFAsyncPageRowSavedAlertView(viewModel: viewModel)
                            }
                            
                        }

                        Spacer()

                        thumbnailView
                    }
                    .environment(\.layoutDirection, viewModel.project.isRTL ? .rightToLeft : .leftToRight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: maxReadableWidth, minHeight: 124, alignment: .leading)
                
                Spacer(minLength: 0)
            }
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
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        viewModel.geometryFrame = geometry.frame(in: .global)
                    }
            }
            .allowsHitTesting(false)
        )
        .contextMenu {
            Button {
                onTap()
            } label: {
                Text(viewModel.localizedStrings.open)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
            
            Button {
                onDelete()
            } label: {
                Text(viewModel.localizedStrings.removeFromSaved)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .bookmark) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
 
            Button {
                onOpenInNewTab()
            } label: {
                Text(viewModel.localizedStrings.openInNewTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
            
            Button {
                onOpenInBackgroundTab()
            } label: {
                Text(viewModel.localizedStrings.openInBackgroundTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
            
            Button {
                onShare(viewModel.geometryFrame)
            } label: {
                Text(viewModel.localizedStrings.share)
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
                    Button(action: onDelete) {
                        Image(uiImage: deleteIcon)
                    }
                    .tint(Color(uiColor: appEnvironment.theme.destructive))

                    Button(action: {
                        onShare(viewModel.geometryFrame)
                    }) {
                        Image(uiImage: shareIcon)
                    }
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
            }
        }
    }
    
    private func getPreviewViewModel(from viewModel: WMFAsyncPageRowSavedViewModel) -> WMFArticlePreviewViewModel {
        var url: URL? = nil
        if let siteURL = viewModel.project.siteURL {
            var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
            components?.path = "/wiki/\(viewModel.title)"
            url = components?.url
        }
        
        return WMFArticlePreviewViewModel(url: url, titleHtml: viewModel.title, description: viewModel.description, imageURLString: viewModel.imageURL?.absoluteString, isSaved: true, snippet: viewModel.snippet)
    }
}
