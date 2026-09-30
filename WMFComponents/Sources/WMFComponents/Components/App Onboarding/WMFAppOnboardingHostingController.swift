import UIKit
import Combine

@MainActor
public final class WMFAppOnboardingHostingController: WMFComponentHostingController<WMFAppOnboardingView> {

    private let viewModel: WMFAppOnboardingViewModel
    private var stepSubscription: AnyCancellable?

    public init(viewModel: WMFAppOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFAppOnboardingView(viewModel: viewModel))

        stepSubscription = viewModel.$currentStepIndex
            .removeDuplicates()
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
            }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The intro step is always dark, so it needs a light status bar even in light mode.
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return viewModel.currentStep == .intro ? .lightContent : .default
    }
}
