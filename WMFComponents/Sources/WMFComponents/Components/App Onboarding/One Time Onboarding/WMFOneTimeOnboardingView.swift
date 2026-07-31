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
                        .padding(.top, 32)
                        .padding(.bottom, 32)
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

            Divider()
                .foregroundStyle(Color(uiColor: theme.border))

            VStack(spacing: 12) {
                Button {
                    viewModel.onCustomize?()
                } label: {
                    Text(viewModel.customizeButtonTitle)
                        .font(Font(WMFFont.for(.boldCallout)))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(uiColor: theme.link), in: Capsule())
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.OneTimeOnboarding.customizeButton)

                Button {
                    viewModel.onAutoSetup?()
                } label: {
                    Text(viewModel.autoSetupButtonTitle)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.OneTimeOnboarding.autoSetupButton)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
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
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color(uiColor: theme.link))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(Font(WMFFont.for(.boldSubheadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                Text(item.body)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
