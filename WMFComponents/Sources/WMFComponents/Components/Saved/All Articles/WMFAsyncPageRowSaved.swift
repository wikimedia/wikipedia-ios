import SwiftUI
import WMFData

struct WMFSavedArticleAlertView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let alertType: WMFSavedArticleAlertType
    
    // TODO: localize
    private var alertString: String? {
        switch alertType {
        case .listLimitExceeded:
            return "List limit exceeded, unable to sync article"
        case .entryLimitExceeded:
            return "Article limit exceeded, unable to sync article"
        case .genericNotSynced:
            return "Not synced"
        case .downloading:
            return "Article queued to be downloaded"
        case .articleError(let errorDescription):
            return errorDescription
        case .none:
            return nil
        }
    }
    
    var body: some View {
        if let alertString = alertString {
            HStack(spacing: 4) {
                if let icon = WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangle, font: .semiboldCaption1) {
                    Image(uiImage: icon)
                }
                Text(alertString)
                    .font(Font(WMFFont.for(.semiboldCaption1)))
            }
            .foregroundColor(Color(uiColor: appEnvironment.theme.warning))
        }
    }
}

struct WMFAsyncPageRowSaved: View {

    @ObservedObject var viewModel: WMFAsyncPageRowSavedViewModel
    let isEditing: Bool
    let isSelected: Bool
    let theme: WMFTheme
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: (CGRect) -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    selectionIndicator
                }
                
                HStack(spacing: 12) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.title)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundColor(Color(uiColor: theme.text))
                            .lineLimit(1)

                        
                        Text(viewModel.description ?? " ")
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .lineLimit(1)
                        
                        Spacer()

                        
                        if viewModel.isAlertHidden {
                            if !viewModel.readingListNames.isEmpty {
                                readingListTags
                            }
                        } else {
                            WMFSavedArticleAlertView(alertType: viewModel.alertType)
                        }
                        
                    }

                    Spacer()

                    thumbnailView
                }
                .environment(\.layoutDirection, viewModel.project.isRTL ? .rightToLeft : .leftToRight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
        }
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            
            if !isEditing {
                
                if let shareIcon = WMFIcon.share,
                   let deleteIcon = WMFIcon.delete {
                    Button(action: onDelete) {
                        Image(uiImage: deleteIcon)
                    }
                    .tint(Color(uiColor: theme.destructive))

                    Button(action: {
                        onShare(viewModel.geometryFrame)
                    }) {
                        Image(uiImage: shareIcon)
                    }
                    .tint(Color(uiColor: theme.secondaryAction))
                }
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        Group {
            if let uiImage = viewModel.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(uiColor: theme.midBackground)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.secondaryText))
            .font(.system(size: 22))
    }

    private var readingListTags: some View {
        let names = viewModel.readingListNames
        
        return ViewThatFits(in: .horizontal) {
            // Try all tags
            if names.count >= 1 {
                HStack(spacing: 4) {
                    ForEach(names, id: \.self) { name in
                        tagView(for: name)
                    }
                }
            }
            
            // Try all but one + overflow
            if names.count >= 2 {
                HStack(spacing: 4) {
                    ForEach(names.dropLast(1), id: \.self) { name in
                        tagView(for: name)
                    }
                    overflowTag(count: 1)
                }
            }
            
            // Try all but two + overflow
            if names.count >= 3 {
                HStack(spacing: 4) {
                    ForEach(names.dropLast(2), id: \.self) { name in
                        tagView(for: name)
                    }
                    overflowTag(count: 2)
                }
            }
            
            // Try first two + overflow
            if names.count >= 3 {
                HStack(spacing: 4) {
                    tagView(for: names[0])
                    tagView(for: names[1])
                    overflowTag(count: names.count - 2)
                }
            }
            
            // Try first one + overflow
            if names.count >= 2 {
                HStack(spacing: 4) {
                    tagView(for: names[0])
                    overflowTag(count: names.count - 1)
                }
            }
            
            // Fallback: just overflow
            if names.count >= 1 {
                overflowTag(count: names.count)
            }
        }
    }

    private func tagView(for listName: String) -> some View {
        Text(listName)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundColor(Color(uiColor: theme.link))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(uiColor: theme.link).opacity(0.1))
            .cornerRadius(4)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
    }

    private func overflowTag(count: Int) -> some View {
        Text("+\(count)")
            .font(Font(WMFFont.for(.caption1)))
            .foregroundColor(Color(uiColor: theme.link))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(uiColor: theme.link).opacity(0.1))
            .cornerRadius(4)
            .fixedSize(horizontal: true, vertical: true)
    }
}
