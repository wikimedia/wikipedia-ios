import SwiftUI
import _PassKit_SwiftUI

@objc public protocol WMFDonateDelegate: AnyObject {
    func donateDidTapProblemsDonatingLink()
    func donateDidTapOtherWaysToGive()
    func donateDidTapFrequentlyAskedQuestions()
    func donateDidTapTaxDeductibilityInformation()
    func donateDidSuccessfullySubmitPayment()
}

struct WMFDonateView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDonateViewModel
    
    init(viewModel: WMFDonateViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Group {
                    WMFDonateAmountButtonGroupView(viewModel: viewModel)
                    Spacer()
                        .frame(height: 24)
                }
                
                Group {
                    WMFDonateAmountTextfield(viewModel: viewModel.textfieldViewModel)
                    if let errorViewModel = viewModel.errorViewModel {
                        WMFDonateErrorView(viewModel: errorViewModel)
                    }
                    Spacer()
                        .frame(height: 24)
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 12) {
                        WMFDonateOptInView(viewModel: viewModel.transactionFeeOptInViewModel)
                        WMFDonateOptInView(viewModel: viewModel.monthlyRecurringViewModel)
                        if let emailOptInViewModel = viewModel.emailOptInViewModel {
                            WMFDonateOptInView(viewModel: emailOptInViewModel)
                        }
                    }
                    Spacer()
                        .frame(height: 20)
                }
                
                Group {
                    PayWithApplePayButton(.donate) {
                        viewModel.textfieldViewModel.hasFocus = false
                        viewModel.logTappedApplePayButton()
                        viewModel.validateAndSubmit()
                        if let errorViewModel = viewModel.errorViewModel {
                            errorViewModel.hasAccessibilityFocus = true
                        }
                    } fallback: {
                        
                    }
                    .payWithApplePayButtonStyle(appEnvironment.theme.applePayPaymentButtonStyle)
                    .accessibilityHint(viewModel.accessibilityDonateButtonHint ?? "")
                        .frame(height: 42)
                        .padding([.leading, .trailing], sizeClassDonateButtonPadding)
                    Spacer()
                        .frame(height: 20)
                }
                
                Group {
                    VStack(alignment: .leading, spacing: 15) {
                        WMFAppleFinePrint(viewModel: viewModel)
                        WMFWikimediaFinePrint(text: viewModel.localizedStrings.wikimediaFinePrint1, isAttributed: true)
                        WMFWikimediaFinePrint(text: viewModel.localizedStrings.wikimediaFinePrint2, isAttributed: false)
                    }
                    Spacer()
                        .frame(height: 40)
                    WMFDonateHelpLinks(viewModel: viewModel)
                    Spacer()
                }
            }
            .padding(EdgeInsets(top: 16, leading: sizeClassHorizontalPadding, bottom: 16, trailing: sizeClassHorizontalPadding))
        }
        .background(Color(appEnvironment.theme.paperBackground))
    }
    
    private var sizeClassHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private var sizeClassDonateButtonPadding: CGFloat {
        horizontalSizeClass == .regular ? 120 : 0
    }
}

private struct WMFDonateAmountButtonGroupView: View {
    
    @ObservedObject var viewModel: WMFDonateViewModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.sizeCategory) var contentSizeCategory
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            if shouldDisplayVertically {
                ForEach(viewModel.buttonViewModels) { buttonViewModel in
                    WMFDonateAmountButtonView(viewModel: buttonViewModel)
                }
            } else {
                HStack(spacing: 12) {
                    let firstThree = viewModel.buttonViewModels.prefix(3)
                    ForEach(firstThree) { buttonViewModel in
                        WMFDonateAmountButtonView(viewModel: buttonViewModel)
                    }
                }
                HStack(spacing: 12) {
                    let lastFour = viewModel.buttonViewModels.suffix(4)
                    ForEach(lastFour) { buttonViewModel in
                        WMFDonateAmountButtonView(viewModel: buttonViewModel)
                    }
                }
            }
        }
    }
    
    private var shouldDisplayVertically: Bool {
        return horizontalSizeClass == .compact && (contentSizeCategory == .accessibilityLarge ||
                                                   contentSizeCategory == .accessibilityExtraLarge ||
                                                   contentSizeCategory == .accessibilityExtraExtraLarge ||
                                                   contentSizeCategory == .accessibilityExtraExtraExtraLarge)
    }
}

private struct WMFDonateAmountButtonView: View {
    @ObservedObject var viewModel: WMFDonateViewModel.AmountButtonViewModel
    
    var body: some View {
        let configuration = WMFPriceButton.Configuration(currencyCode: viewModel.currencyCode, canDeselect: false, accessibilityHint: viewModel.accessibilityHint)
        WMFPriceButton(configuration: configuration, amount: $viewModel.amount, isSelected: $viewModel.isSelected, loggingTapAction: {
            viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapAmountPresetButton)
        })
    }
}

private struct WMFDonateAmountTextfield: View {
    @ObservedObject var viewModel: WMFDonateViewModel.AmountTextFieldViewModel
    
    var body: some View {
        let configuration = WMFPriceTextField.Configuration(currencyCode: viewModel.currencyCode, focusOnAppearance: true, doneTitle: viewModel.localizedStrings.doneTitle, textfieldAccessibilityHint: viewModel.localizedStrings.textfieldAccessibilityHint, doneAccessibilityHint: viewModel.localizedStrings.doneAccessibilityHint)
        WMFPriceTextField(configuration: configuration, amount: $viewModel.amount, hasFocus: $viewModel.hasFocus)
    }
}

private struct WMFDonateErrorView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDonateViewModel.ErrorViewModel
    
    @AccessibilityFocusState var accessibilityFocus: Bool
    
    var body: some View {
        Spacer()
            .frame(height: 12)
        HStack {
            Text(viewModel.displayText)
                .font(Font(WMFFont.for(.mediumSubheadline)))
                .foregroundColor(Color(appEnvironment.theme.destructive))
                .accessibilityFocused($accessibilityFocus)
                .onChange(of: viewModel.hasAccessibilityFocus) {
                    accessibilityFocus = $0
                }
                .onChange(of: accessibilityFocus) {
                    viewModel.hasAccessibilityFocus = $0
                }
            Spacer()
        }
    }
}

private struct WMFDonateOptInView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDonateViewModel.OptInViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            WMFCheckmarkView(isSelected: viewModel.isSelected, configuration: WMFCheckmarkView.Configuration(style: .checkbox))
                .offset(x: 0, y: 2.5)
                .accessibilityHidden(true)
            Text(viewModel.localizedStrings.text)
                .foregroundColor(Color(appEnvironment.theme.text))
                .font(Font(WMFFont.for(.subheadline)))
                .accessibilityHint(viewModel.localizedStrings.accessibilityHint)
                .accessibilityAddTraits( viewModel.isSelected ? [.isSelected] : [])
            Spacer()
        }
        .onTapGesture {
            viewModel.isSelected.toggle()
        }
    }
}

private struct WMFDonateHelpLink: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let text: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button {
                action()
            } label: {
                Text(text)
                    .foregroundColor(Color(appEnvironment.theme.link))
                    .font(Font(WMFFont.for(.subheadline)))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
    }
}

private struct WMFDonateHelpLinks: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFDonateViewModel
    
    init(viewModel: WMFDonateViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WMFDonateHelpLink(text: viewModel.localizedStrings.helpLinkProblemsDonating) {
                viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapProblemsDonating)
                viewModel.coordinatorDelegate?.handleDonateAction(.nativeFormDidTapProblemsDonating)
            }
            WMFDonateHelpLink(text: viewModel.localizedStrings.helpLinkOtherWaysToGive) {
                viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapOtherWaysToGive)
                viewModel.coordinatorDelegate?.handleDonateAction(.nativeFormDidTapOtherWaysToGive)
            }
            WMFDonateHelpLink(text: viewModel.localizedStrings.helpLinkFrequentlyAskedQuestions) {
                viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapFAQ)
                viewModel.coordinatorDelegate?.handleDonateAction(.nativeFormDidTapFAQ)
            }
            WMFDonateHelpLink(text: viewModel.localizedStrings.helpLinkTaxDeductibilityInformation) {
                viewModel.loggingDelegate?.handleDonateLoggingAction(.nativeFormDidTapTaxInfo)
                viewModel.coordinatorDelegate?.handleDonateAction(.nativeFormDidTapTaxInfo)
            }
        }
    }
}

private struct WMFAppleFinePrint: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFDonateViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.localizedStrings.appleFinePrint)
                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                .font(Font(WMFFont.for(.caption1)))
            Spacer()
        }
    }
}

private struct WMFWikimediaFinePrint: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let text: String
    let isAttributed: Bool
    
    var attributedString: AttributedString? {
        if let finePrint = try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return finePrint
        }
        
        return AttributedString(text)
    }
    
    @ViewBuilder
    var contentView: some View {
        if isAttributed,
           let attributedString {
            Text(attributedString)
        } else {
            Text(text)
        }
    }
    
    var body: some View {
        HStack {
            contentView
                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                .font(Font(WMFFont.for(.caption1)))
            
            Spacer()
        }
    }
}
