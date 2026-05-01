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
                List {
                    ForEach(viewModel.articleRows) { row in
                        WMFPageRow(
                            needsLimitedFontSize: false,
                            id: row.id,
                            titleHtml: row.title,
                            articleDescription: row.description,
                            imageURLString: row.thumbnailURLString,
                            titleLineLimit: 2,
                            isSaved: false,
                            showsSwipeActions: false,
                            loadImageAction: { _ in row.uiImage }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.onTapArticle?(row.title, row.project)
                        }
                        .listRowBackground(Color(uiColor: theme.paperBackground))
                        .listRowSeparatorTint(Color(uiColor: theme.border))
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .onAppear {
            viewModel.load()
        }
    }
}
