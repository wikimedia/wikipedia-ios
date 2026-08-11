import SwiftUI
import WMFData

public struct WMFOneTimeOnboardingView: View {

    @ObservedObject var viewModel: WMFOneTimeOnboardingViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    public init(viewModel: WMFOneTimeOnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        WMFOnboardingView(
            viewModel: WMFOnboardingViewModel(
                title: viewModel.title,
                cells: viewModel.featureItems.map { item in
                    WMFOnboardingViewModel.WMFOnboardingCellViewModel(
                        icon: WMFSFSymbolIcon.for(symbol: item.symbol),
                        title: item.title,
                        subtitle: item.body,
                        tintBlue: true
                    )
                },
                primaryButtonTitle: viewModel.customizeButtonTitle,
                secondaryButtonTitle: viewModel.autoSetupButtonTitle,
                primaryButtonAction: { viewModel.onCustomize?() },
                secondaryButtonAction: { viewModel.onAutoSetup?() }
            )
        )
    }
}

#Preview("Light") {
    WMFOneTimeOnboardingView(viewModel: WMFOneTimeOnboardingViewModel())
}

#Preview("Dark") {
    WMFOneTimeOnboardingView(viewModel: WMFOneTimeOnboardingViewModel())
        .preferredColorScheme(.dark)
}
