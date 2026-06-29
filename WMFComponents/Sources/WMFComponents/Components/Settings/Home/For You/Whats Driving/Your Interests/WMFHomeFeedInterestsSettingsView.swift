// TODO: This is temporary UI — topic chips and article grid are placeholders pending final design.

import SwiftUI

public struct WMFHomeFeedInterestsSettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedInterestsSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.topics, id: \.self) { topic in
                            TopicChipView(
                                title: topic.displayName,
                                isSelected: viewModel.selectedTopics.contains(topic),
                                theme: theme
                            )
                            .onTapGesture {
                                viewModel.toggleTopic(topic)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if viewModel.isFetchingArticles {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else if !viewModel.gridViewModels.isEmpty {
                    WMFInterestArticleGridView(
                        viewModels: viewModel.gridViewModels,
                        theme: theme,
                        onTap: { vm in
                            viewModel.toggleArticleSelection(vm)
                        }
                    )
                } else {
                    HStack {
                        Spacer()
                        Text(viewModel.emptyMessage)
                            .font(Font(WMFFont.for(.headline)))
                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.top, 80)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}

private struct TopicChipView: View {
    let title: String
    let isSelected: Bool
    let theme: WMFTheme

    var body: some View {
        Text(title)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundStyle(isSelected ? Color(uiColor: theme.paperBackground) : Color(uiColor: theme.link))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(uiColor: theme.link) : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color(uiColor: theme.link), lineWidth: 1.5)
            )
    }
}
