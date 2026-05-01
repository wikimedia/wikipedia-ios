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
                Text(viewModel.selectedTopic.displayName)
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
        VStack {
            Spacer()
            Text(viewModel.localizedStrings.noArticlesMessage)
                .font(Font(WMFFont.for(.body)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

}
