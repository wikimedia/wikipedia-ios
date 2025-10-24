import SwiftUI

public struct WMFActivityTabView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public init(viewModel: WMFActivityTabViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 20) {
                VStack(alignment: .center, spacing: 8) {
                    Text(viewModel.usernamesReading)
                        .foregroundColor(Color(uiColor: theme.text))
                        .font(Font(WMFFont.for(.boldHeadline)))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(viewModel.localizedStrings.onWikipediaiOS)
                        .font(.custom("Menlo", size: 11, relativeTo: .caption2))
                        .foregroundColor(Color(uiColor: theme.text))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: WMFColor.blue100))
                        )
                }
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .center, spacing: 8) {
                        hoursMinutesRead
                        Text(viewModel.localizedStrings.timeSpentReading)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundColor(Color(uiColor: theme.text))
                    }
                    .frame(maxWidth: .infinity)
                    // Start of modules on top section
                    articlesReadModule
                    if let model = viewModel.articlesReadViewModel {
                        if !model.topCategories.isEmpty {
                            topCategoriesModule(categories: model.topCategories)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            viewModel.viewDidLoad()
			viewModel.hasSeenActivityTab()
        }
        .padding(.top, 16)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(uiColor: theme.paperBackground), location: 0.00),
                    Gradient.Stop(color: Color(uiColor: WMFColor.blue100), location: 1.00)
                ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
    }
    
    private var hoursMinutesRead: some View {
        Text(viewModel.hoursMinutesRead)
            .font(Font(WMFFont.for(.boldTitle1)))
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 221/255, green: 51/255, blue: 51/255),   // #DD3333
                        Color(red: 1.0, green: 149/255, blue: 0),           // #FF9500
                        Color(red: 1.0, green: 204/255, blue: 51/255),      // #FFCC33
                        Color(red: 102/255, green: 153/255, blue: 1.0)      // #6699FF
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Text(viewModel.hoursMinutesRead)
                        .font(Font(WMFFont.for(.boldTitle1)))
                )
            )

    }
    
    private var articlesReadModule: some View {
        Group {
            if let model = viewModel.articlesReadViewModel {
                WMFActivityTabInfoCardView(
                    icon: WMFSFSymbolIcon.for(symbol: .bookPages),
                    title: viewModel.localizedStrings.totalArticlesRead,
                    dateText: model.dateTimeLastRead,
                    amount: model.totalArticlesRead,
                    onTapModule: {
                        print("Tapped module")
                        // TODO: Navigate to history below
                    }
                )
            } else {
                WMFActivityTabInfoCardView(
                    icon: WMFSFSymbolIcon.for(symbol: .bookPages),
                    title: viewModel.localizedStrings.totalArticlesRead,
                    dateText: nil,
                    amount: 0,
                    onTapModule: {
                        print("Tapped module")
                        // TODO: Navigate to history below
                    }
                )
            }
        }
    }
    
    private func topCategoriesModule(categories: [String]) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                if let icon = WMFSFSymbolIcon.for(symbol: .rectangle3) {
                    Image(uiImage: icon)
                }
                Text(viewModel.localizedStrings.topCategories)
                    .foregroundStyle(Color(theme.text))
                    .font(Font(WMFFont.for(.boldCaption1)))
                Spacer()
            }
            ForEach(categories.indices, id: \.self) { index in
                let category = categories[index]
                VStack(alignment: .leading, spacing: 16) {
                    Text(category)
                        .foregroundStyle(Color(theme.text))
                        .font(Font(WMFFont.for(.callout)))
                    
                    if index < categories.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(theme.baseBackground), lineWidth: 0.5)
        )
    }
}
