import SwiftUI
import WMFData

public struct WMFTrendingCountryView: View {

    @ObservedObject public var viewModel: WMFTrendingCountryViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFTrendingCountryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: theme.link)))
                    Text(viewModel.localizedStrings.loadingMessage)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.articleRows.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.localizedStrings.noArticlesMessage)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.articleRows.enumerated()), id: \.element.id) { index, row in
                            WMFTrendingArticleCard(
                                row: row,
                                rank: index,
                                country: viewModel.countryName,
                                projectPageViews: viewModel.projectPageViews,
                                onTap: {
                                    viewModel.onTapArticle?(row.title, row.project)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .onAppear {
            viewModel.load()
        }
    }
}
