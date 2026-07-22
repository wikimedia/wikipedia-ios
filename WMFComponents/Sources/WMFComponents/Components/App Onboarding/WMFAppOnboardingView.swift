import SwiftUI

public struct WMFAppOnboardingView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    public init(viewModel: WMFAppOnboardingViewModel) {
        self.viewModel = viewModel
    }

    /// The intro step is always dark, regardless of the app theme.
    private var theme: WMFTheme {
        return viewModel.currentStep == .intro ? .dark : appEnvironment.theme
    }

    private var colorScheme: ColorScheme {
        return viewModel.currentStep == .intro ? .dark : appEnvironment.theme.preferredColorScheme
    }

    /// Bottom inset so scrollable step content isn't covered by the floating toolbar.
    static let toolbarContentInset: CGFloat = 96

    public var body: some View {
        ZStack(alignment: .bottom) {
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            if viewModel.showsToolbar {
                WMFAppOnboardingToolbar(viewModel: viewModel, theme: theme)
            }
        }
        .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
        .environment(\.colorScheme, colorScheme)
        // Cap Dynamic Type for the whole flow: beyond accessibility2 the step titles render
        // one word per line and collide with the floating toolbar. Step views resolve their
        // WMFFonts against this capped size (see WMFFont.for(_:sized:)).
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .intro:
            WMFAppOnboardingIntroView(viewModel: viewModel)
        case .dataPrivacy:
            WMFAppOnboardingDataPrivacyView(viewModel: viewModel, theme: theme)
        case .languages:
            WMFAppOnboardingLanguagesView(viewModel: viewModel, theme: theme)
        case .personalizationIntro:
            WMFAppOnboardingPersonalizationIntroView(viewModel: viewModel, theme: theme)
        case .interests:
            VStack(spacing: 0) {
                WMFHomeFeedInterestsSettingsView(viewModel: viewModel.interestsViewModel, bottomContentInset: Self.toolbarContentInset)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Interests.view)
        case .feedPreference:
            WMFAppOnboardingFeedPreferenceView(viewModel: viewModel.feedPreferenceViewModel, theme: theme)
                .onAppear {
                    viewModel.feedPreferenceViewModel.loadIfNeeded()
                }
        case .loading:
            WMFAppOnboardingLoadingView(viewModel: viewModel, theme: theme)
        }
    }
}

struct WMFAppOnboardingToolbar: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    let theme: WMFTheme

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    private static let controlHeight: CGFloat = 44

    // Frame-bounds the chevron: symbol images built from preferred fonts re-scale against the
    // live (uncapped) system content size at render time, so the glyph must be constrained
    // explicitly. The metric follows the capped environment.
    @ScaledMetric private var chevronSize: CGFloat = 18

    var body: some View {
        ZStack {
            if viewModel.showsSkipAndDots {
                HStack {
                    Button(viewModel.skipTitle) {
                        viewModel.skip()
                    }
                    .font(Font(WMFFont.for(.body, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .padding(.horizontal, 20)
                    .frame(height: Self.controlHeight)
                    .modifier(WMFAppOnboardingPillBackground(theme: theme, isInteractive: true))
                    .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.skipButton)

                    Spacer()
                }

                dots
            }

            HStack {
                Spacer()
                nextButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.personalizationSteps.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentDotIndex ? Color(uiColor: theme.text) : Color(uiColor: theme.secondaryText).opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: Self.controlHeight)
        .modifier(WMFAppOnboardingPillBackground(theme: theme, isInteractive: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.pageIndicatorAccessibilityLabel ?? "")
    }

    /// The intro step highlights the next button as white-on-link; other steps keep it neutral.
    private var isIntroStep: Bool {
        viewModel.currentStep == .intro
    }

    private var nextButton: some View {
        Button {
            withAnimation {
                viewModel.advance()
            }
        } label: {
            Group {
                if let chevron = WMFSFSymbolIcon.for(symbol: .chevronForward, font: .boldHeadline, compatibleWith: dynamicTypeSize.wmfTraitCollection) {
                    Image(uiImage: chevron)
                        .resizable()
                        .scaledToFit()
                        .frame(width: chevronSize, height: chevronSize)
                        .foregroundStyle(isIntroStep ? Color.white : Color(uiColor: theme.text))
                }
            }
            .frame(width: Self.controlHeight, height: Self.controlHeight)
        }
        .modifier(WMFAppOnboardingPillBackground(theme: theme, isInteractive: true, tint: isIntroStep ? Color(uiColor: theme.link) : nil))
        .accessibilityLabel(viewModel.nextAccessibilityLabel)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.nextButton)
    }
}

private struct WMFAppOnboardingPillBackground: ViewModifier {
    let theme: WMFTheme
    let isInteractive: Bool
    var tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glass, in: Capsule())
        } else {
            content
                .background(
                    Capsule()
                        .fill(tint ?? Color(uiColor: theme.midBackground).opacity(0.9))
                )
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var glass: Glass = .regular
        if let tint {
            glass = glass.tint(tint)
        }
        if isInteractive {
            glass = glass.interactive()
        }
        return glass
    }
}
