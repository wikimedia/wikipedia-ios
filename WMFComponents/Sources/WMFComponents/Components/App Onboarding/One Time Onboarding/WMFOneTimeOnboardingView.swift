import SwiftUI
import WMFData

public struct WMFOneTimeOnboardingView: View {

    @ObservedObject var viewModel: WMFOneTimeOnboardingViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFOneTimeOnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 70)
                        .padding(.bottom, 36)
                        .padding(.horizontal, 24)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.featureItems) { item in
                            featureRow(item: item)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }

            VStack(spacing: 16) {
                Button {
                    viewModel.onCustomize?()
                } label: {
                    Text(viewModel.customizeButtonTitle)
                        .font(Font(WMFFont.for(.boldCallout)))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: theme.link), in: Capsule())
                }
                //.accessibilityIdentifier(AccessibilityIdentifiers.OneTimeOnboarding.customizeButton)

                Button {
                    viewModel.onAutoSetup?()
                } label: {
                    Text(viewModel.autoSetupButtonTitle)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                //.accessibilityIdentifier(AccessibilityIdentifiers.OneTimeOnboarding.autoSetupButton)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func featureRow(item: WMFOneTimeOnboardingViewModel.FeatureItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            if let image = WMFSFSymbolIcon.for(symbol: item.symbol) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color(uiColor: theme.link))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                Text(item.body)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundStyle(Color(uiColor: theme.inputAccessoryButtonTint))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    WMFOneTimeOnboardingView(viewModel: WMFOneTimeOnboardingViewModel())
}

#Preview("Dark") {
    WMFOneTimeOnboardingView(viewModel: WMFOneTimeOnboardingViewModel())
        .preferredColorScheme(.dark)
}
