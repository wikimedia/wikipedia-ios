import SwiftUI
import WebKit

public struct WMFYearInReviewView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }


    public var body: some View {
        NavigationView {
            VStack {
                WMFYearInReviewHeaderView(viewModel: viewModel)
                WMFYearInReviewBodyView(viewModel: viewModel)
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                if !viewModel.isShowingIntro {
                    ToolbarItem(placement: .bottomBar) {
                        WMFYearInReviewToolbarView(viewModel: viewModel, needShareButton: !viewModel.isLastSlide)
                    }
                }
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
        .environment(\.openURL, OpenURLAction { url in
            viewModel.tappedLearnMore(url: url)
            return .handled
        })
    }

}
