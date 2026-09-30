import SwiftUI

// MARK: - Intro

/// The first onboarding step. Always rendered with the black theme, regardless of the app theme.
struct WMFAppOnboardingIntroView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    private let theme = WMFTheme.black

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Template rendering at the call site: the shared "wikipedia" asset is
                    // black, and other usages (e.g. Which Came First sharing) rely on that.
                    Image("wikipedia", bundle: .module)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .accessibilityLabel(viewModel.introWordmark)
                        .padding(.top, 16)

                    Text(viewModel.introTitle)
                        .font(Font(WMFFont.for(.georgiaTitle1, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .padding(.top, 24)

                    Text(viewModel.introBody)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))

                    Button(viewModel.introLearnMore) {
                        viewModel.didTapLearnMoreAboutWikipedia()
                    }
                    .font(Font(WMFFont.for(.boldCallout, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: theme.link))
                    .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.learnMoreLink)
                }
                .padding(.horizontal, 32)
            }

            Image("onboarding_intro", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                // 30pt gap to the toolbar: 8pt toolbar bottom padding + 44pt control height + 30
                .padding(.bottom, 82)
        }
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.introView)
    }
}

// MARK: - Data & Privacy

struct WMFAppOnboardingDataPrivacyView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    let theme: WMFTheme

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    // Not real destinations: these identify which attributed-string link was tapped in
    // the OpenURLAction handler. The actual URLs are presented app-side via the coordinator.
    private static let privacyPolicyLinkToken = "wmf-app-onboarding://privacy-policy"
    private static let termsOfUseLinkToken = "wmf-app-onboarding://terms-of-use"

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WMFGIFImageView("onboarding_data")
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)

                    Text(viewModel.dataPrivacyTitle)
                        .font(Font(WMFFont.for(.boldTitle1, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))

                    Text(viewModel.dataPrivacyBody)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))

                    linksText
                }
                .padding(.horizontal, 32)
                // Center the content block vertically; stays scrollable at large type sizes
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.dataPrivacyView)
    }

    private var linksText: some View {
        Text(linksAttributedString)
            .font(Font(WMFFont.for(.boldCallout, sized: dynamicTypeSize)))
            .environment(\.openURL, OpenURLAction { url in
                switch url.absoluteString {
                case Self.privacyPolicyLinkToken:
                    viewModel.didTapPrivacyPolicy()
                case Self.termsOfUseLinkToken:
                    viewModel.didTapTermsOfUse()
                default:
                    break
                }
                return .handled
            })
            .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.privacyLinks)
    }

    private var linksAttributedString: AttributedString {
        let sentence = String.localizedStringWithFormat(viewModel.dataPrivacyLinksFormat, viewModel.dataPrivacyPolicyLinkText, viewModel.dataPrivacyTermsLinkText)
        var attributed = AttributedString(sentence)
        attributed.foregroundColor = Color(uiColor: theme.text)

        if let privacyRange = attributed.range(of: viewModel.dataPrivacyPolicyLinkText) {
            attributed[privacyRange].link = URL(string: Self.privacyPolicyLinkToken)
            attributed[privacyRange].foregroundColor = Color(uiColor: theme.link)
        }
        if let termsRange = attributed.range(of: viewModel.dataPrivacyTermsLinkText) {
            attributed[termsRange].link = URL(string: Self.termsOfUseLinkToken)
            attributed[termsRange].foregroundColor = Color(uiColor: theme.link)
        }
        return attributed
    }
}

// MARK: - Languages

struct WMFAppOnboardingLanguagesView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    let theme: WMFTheme

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    /// Minimum space above the image and below the pinned button. When the content is
    /// shorter than the screen, the leftover space is split between the two so the view
    /// reads vertically balanced (e.g. short lists, iPad).
    private static let minimumTopSpacing: CGFloat = 60
    private static let minimumBottomSpacing: CGFloat = 82
    private static let buttonTopSpacing: CGFloat = 16

    /// Scales with Dynamic Type so language rows don't clip larger text.
    @ScaledMetric private var languageRowHeight: CGFloat = 56

    @State private var scrollContentHeight: CGFloat = 0
    @State private var buttonRowHeight: CGFloat = 0

    private func extraSpacing(for availableHeight: CGFloat) -> CGFloat {
        let idealHeight = Self.minimumTopSpacing + scrollContentHeight + Self.buttonTopSpacing + buttonRowHeight + Self.minimumBottomSpacing
        return max(0, (availableHeight - idealHeight) / 2)
    }

    var body: some View {
        GeometryReader { geometry in
            let extra = extraSpacing(for: geometry.size.height)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        WMFGIFImageView("onboarding_language")
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)

                        Text(viewModel.languagesTitle)
                            .font(Font(WMFFont.for(.boldTitle1, sized: dynamicTypeSize)))
                            .foregroundStyle(Color(uiColor: theme.text))

                        Text(viewModel.languagesNotice)
                            .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                            .foregroundStyle(Color(uiColor: theme.text))

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.languages) { language in
                                Divider()
                                    .overlay(Color(uiColor: theme.border))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.displayName)
                                        .font(Font(WMFFont.for(language.isPrimary ? .boldCallout : .callout, sized: dynamicTypeSize)))
                                        .foregroundStyle(Color(uiColor: theme.text))
                                    if language.isPrimary {
                                        Text(viewModel.languagesPrimaryLabel)
                                            .font(Font(WMFFont.for(.subheadline, sized: dynamicTypeSize)))
                                            .foregroundStyle(Color(uiColor: theme.secondaryText))
                                    }
                                }
                                .frame(minHeight: languageRowHeight, alignment: .leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .background(WMFHeightReader(height: $scrollContentHeight))
                    .padding(.top, Self.minimumTopSpacing + extra)
                }

                // Pinned under the scrolling content so long language lists never cover it
                HStack {
                    Button(viewModel.languagesAddOrEdit) {
                        viewModel.didTapAddLanguages()
                    }
                    .font(Font(WMFFont.for(.boldCallout, sized: dynamicTypeSize)))
                    .foregroundStyle(Color(uiColor: theme.link))
                    .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.addLanguagesButton)

                    Spacer()
                }
                .padding(.horizontal, 32)
                .background(WMFHeightReader(height: $buttonRowHeight))
                .padding(.top, Self.buttonTopSpacing)
                .padding(.bottom, Self.minimumBottomSpacing + extra)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.languagesView)
    }
}

/// Reports the natural height of the view it backgrounds, excluding padding applied after it.
private struct WMFHeightReader: View {
    @Binding var height: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear { height = geometry.size.height }
                .onChange(of: geometry.size.height) { _, newValue in
                    height = newValue
                }
        }
    }
}

// MARK: - Personalization intro

struct WMFAppOnboardingPersonalizationIntroView: View {

    @ObservedObject var viewModel: WMFAppOnboardingViewModel
    let theme: WMFTheme

    // The onboarding container caps dynamicTypeSize; fonts resolve against the capped
    // value via WMFFont.for(_:sized:), since WMFFont ignores the SwiftUI cap.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WMFGIFImageView("onboarding_puzzle")
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)

                    Text(viewModel.personalizationTitle)
                        .font(Font(WMFFont.for(.boldTitle1, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))

                    Text(viewModel.personalizationBody1)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))

                    Text(viewModel.personalizationBody2)
                        .font(Font(WMFFont.for(.callout, sized: dynamicTypeSize)))
                        .foregroundStyle(Color(uiColor: theme.text))
                }
                .padding(.horizontal, 32)
                // Center the content block vertically; stays scrollable at large type sizes
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Onboarding.personalizationIntroView)
    }
}
