import SwiftUI
import WebKit

public struct OLDWMFYearInReviewView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: OLDWMFYearInReviewViewModel

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: OLDWMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }


    public var body: some View {
        NavigationView {
            VStack {
                OLDWMFYearInReviewHeaderView(viewModel: viewModel)
                OLDWMFYearInReviewBodyView(viewModel: viewModel)
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                if !viewModel.isShowingIntro {
                    ToolbarItem(placement: .bottomBar) {
                        OLDWMFYearInReviewToolbarView(viewModel: viewModel, needShareButton: !viewModel.isLastSlide)
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
            viewModel.tappedLearnMoreAttributedText(url: url)
            return .handled
        })
    }

}
