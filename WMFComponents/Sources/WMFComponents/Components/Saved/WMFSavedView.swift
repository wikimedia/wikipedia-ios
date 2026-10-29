import SwiftUI
import WMFNativeLocalizations

public struct WMFSavedView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSavedViewModel

    private let title = CommonStrings.savedTabTitle

    public init(viewModel: WMFSavedViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        segmentContentUnderPicker
            .overlay(alignment: .bottom) {
                WMFSavedProgressView(viewModel: viewModel.progressViewModel)
                    .allowsHitTesting(false)
            }
            .background(Color(uiColor: appEnvironment.theme.paperBackground))
            .searchable(
                text: $viewModel.searchText,
                isPresented: $viewModel.isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(viewModel.searchPrompt)
            )
    }

    /// The segment content fills the screen and scrolls under the picker, so the system
    /// scroll edge effect of the navigation bar continues under the picker as it did when the
    /// picker was a scope bar in the UIKit navigation bar.
    @ViewBuilder
    private var segmentContentUnderPicker: some View {
        if #available(iOS 26.0, *) {
            segmentContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaBar(edge: .top, spacing: 0) {
                    segmentPicker
                }
        } else {
            segmentContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top, spacing: 0) {
                    segmentPicker
                        .background(.bar)
                }
        }
    }

    private var segmentPicker: some View {
        let selection = Binding(
            get: { viewModel.segment },
            set: { viewModel.selectSegment($0) }
        )
        return Picker(title, selection: selection) {
            ForEach(WMFSavedViewModel.Segment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, WMFSpacing.large)
        .padding(.vertical, WMFSpacing.small)
        .accessibilityIdentifier(AccessibilityIdentifiers.Saved.segmentPicker)
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch viewModel.segment {
        case .allArticles:
            WMFSavedAllArticlesView(viewModel: viewModel.allArticlesViewModel)
        case .readingLists:
            WMFReadingListsView(viewModel: viewModel.readingListsViewModel)
        }
    }
}
