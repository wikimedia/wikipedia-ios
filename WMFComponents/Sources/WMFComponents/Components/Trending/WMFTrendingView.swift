import SwiftUI
import MapKit
import WMFData

public struct WMFTrendingView: View {

    @ObservedObject public var viewModel: WMFTrendingViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFTrendingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            segmentedControl
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()
                .background(Color(uiColor: theme.border))

            if viewModel.selectedSegment == .map {
                mapView
            } else {
                // Header rows are always visible regardless of loading/error state
                switch viewModel.selectedSegment {
                case .byTopic:
                    topicSelectorRow
                case .byArea:
                    countryHeaderRow
                case .map:
                    EmptyView()
                }

                Divider()
                    .background(Color(uiColor: theme.border))

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.articleRows.isEmpty {
                    emptyView
                } else {
                    articleList
                }
            }
        }
        .background(Color(uiColor: theme.paperBackground))
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $viewModel.isShowingTopicPicker) {
            WMFTrendingTopicPickerView(viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    private var segmentedControl: some View {
        Picker("", selection: $viewModel.selectedSegment) {
            Text(viewModel.localizedStrings.byTopicSegment).tag(WMFTrendingViewModel.Segment.byTopic)
            Text(viewModel.localizedStrings.byAreaSegment).tag(WMFTrendingViewModel.Segment.byArea)
            Text(viewModel.localizedStrings.mapSegment).tag(WMFTrendingViewModel.Segment.map)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedSegment) { _ in
            viewModel.load()
        }
    }

    private var mapView: some View {
        WMFTrendingMapView(
            countries: WMFTrendingCountryAnnotation.all,
            onTapCountry: { country in
                viewModel.onTapCountry?(country)
            }
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private var topicSelectorRow: some View {
        Button {
            viewModel.isShowingTopicPicker = true
        } label: {
            HStack {
                Text(viewModel.localizedStrings.topicPickerTitle)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(Color(uiColor: theme.link))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(Color(uiColor: theme.link))
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.articleRows.enumerated()), id: \.element.id) { index, row in
                    WMFTrendingArticleCard(
                        row: row,
                        rank: index,
                        country: viewModel.detectedCountry,
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

    private var countryHeaderRow: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .font(.subheadline)
            Text(viewModel.detectedCountry)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var loadingView: some View {
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
    }

    private var emptyView: some View {
        let image = WMFSFSymbolIcon.for(symbol: .docTextMagnifyingGlass, font: .title1)
        let strings = WMFEmptyViewModel.LocalizedStrings(
            title: viewModel.emptyMessage,
            subtitle: "",
            titleFilter: nil,
            buttonTitle: nil,
            attributedFilterString: nil
        )
        let emptyViewModel = WMFEmptyViewModel(localizedStrings: strings, image: image, imageColor: theme.secondaryText, numberOfFilters: nil)
        return WMFEmptyView(viewModel: emptyViewModel, type: .noItems, isScrollable: false)
    }

}
