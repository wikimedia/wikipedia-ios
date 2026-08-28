import SwiftUI

struct WMFDonationReminderSetupView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDonationReminderSetupViewModel

    var theme: WMFTheme { appEnvironment.theme }

    private let customAmountErrorIdentifier = "custom-amount-error"

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                scrollContent(scrollProxy: scrollProxy)
            }
            footerButtons
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .animation(.default, value: viewModel.isReminderEnabled)
        .background(Color(theme.paperBackground))
    }

    private func scrollContent(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.localizedStrings.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundColor(Color(theme.text))
                        .accessibilityAddTraits(.isHeader)
                    WMFBetaBadge()
                }
                header
                reminderToggle
                if viewModel.isReminderEnabled {
                    VStack(alignment: .leading, spacing: 24) {
                        triggerGroup
                        amountGroup
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .onChange(of: viewModel.customAmountErrorText) { _, newValue in
            guard newValue != nil else {
                return
            }
            withAnimation {
                scrollProxy.scrollTo(customAmountErrorIdentifier, anchor: .bottom)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.localizedStrings.subtitle)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(theme.text))
            Text(viewModel.localizedStrings.infoText)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(theme.secondaryText))
        }
    }

    private var reminderToggle: some View {
        Toggle(viewModel.localizedStrings.reminderToggleTitle, isOn: $viewModel.isReminderEnabled)
            .font(Font(WMFFont.for(.callout)))
            .foregroundColor(Color(theme.text))
            .tint(Color(theme.link))
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(theme.midBackground)))
    }

    private var triggerGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if let booksImage = WMFSFSymbolIcon.for(symbol: .booksVerticalFill, font: WMFFont.subheadline) {
                    Image(uiImage: booksImage)
                        .foregroundColor(Color(theme.secondaryText))
                }
                Text(viewModel.localizedStrings.triggerGroupTitle)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(theme.text))
                Button {
                    viewModel.isShowingTriggerGroupDetail.toggle()
                } label: {
                    if let infoImage = WMFSFSymbolIcon.for(symbol: .infoCircle, font: WMFFont.caption1) {
                        Image(uiImage: infoImage)
                            .foregroundColor(Color(theme.secondaryText))
                    }
                }
                .accessibilityLabel(viewModel.localizedStrings.triggerDetailAccessibilityLabel)
                .popover(isPresented: $viewModel.isShowingTriggerGroupDetail) {
                    Text(viewModel.localizedStrings.triggerGroupDetail)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(theme.text))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .frame(maxWidth: 240)
                        .presentationCompactAdaptation(.popover)
                        .presentationBackground(Color(theme.popoverBackground))
                }
            }

            HStack(spacing: 12) {
                ForEach(viewModel.configuration.triggerOptions) { triggerOption in
                    WMFSelectablePillButton(label: triggerOption.label, isSelected: viewModel.selectedTriggerOptionIdentifier == triggerOption.id) {
                        viewModel.selectedTriggerOptionIdentifier = triggerOption.id
                    }
                }
                Text(viewModel.localizedStrings.triggerUnitLabel)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(theme.text))
            }
        }
    }

    private var amountGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if let creditCardImage = WMFSFSymbolIcon.for(symbol: .creditCard, font: WMFFont.subheadline) {
                    Image(uiImage: creditCardImage)
                        .foregroundColor(Color(theme.secondaryText))
                }
                Text(viewModel.localizedStrings.amountGroupTitle)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(theme.text))
            }

            HStack(spacing: 12) {
                ForEach(viewModel.configuration.presetAmounts, id: \.self) { presetAmount in
                    WMFPriceButton(
                        configuration: WMFPriceButton.Configuration(currencyCode: viewModel.configuration.currencyCode, canDeselect: false, accessibilityHint: viewModel.localizedStrings.amountButtonAccessibilityHint, cornerRadius: 50),
                        amount: .constant(presetAmount),
                        isSelected: Binding(
                            get: { viewModel.selectedPresetAmount == presetAmount },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectPresetAmount(presetAmount)
                                }
                            }
                        ),
                        loggingTapAction: {}
                    )
                }
            }

            WMFPriceTextField(
                configuration: WMFPriceTextField.Configuration(currencyCode: viewModel.configuration.currencyCode, focusOnAppearance: false, doneTitle: viewModel.localizedStrings.keyboardDoneButtonTitle, textfieldAccessibilityHint: viewModel.localizedStrings.customAmountAccessibilityHint, doneAccessibilityHint: viewModel.localizedStrings.keyboardDoneButtonTitle, cornerRadius: 50),
                amount: $viewModel.customAmount,
                hasFocus: $viewModel.customAmountHasFocus
            )
            .onChange(of: viewModel.customAmount) { _, _ in
                viewModel.customAmountDidChange()
            }

            if let customAmountErrorText = viewModel.customAmountErrorText {
                Text(customAmountErrorText)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(theme.destructive))
                    .id(customAmountErrorIdentifier)
            }
        }
    }

    private var footerButtons: some View {
        VStack(spacing: 12) {
            if viewModel.isReminderEnabled {
                WMFLargeButton(style: .primary, title: viewModel.localizedStrings.confirmButtonTitle) {
                    viewModel.confirm()
                }
                .disabled(!viewModel.canConfirm)
                .opacity(viewModel.canConfirm ? 1 : 0.5)
            }

            WMFSmallButton(configuration: WMFSmallButton.Configuration(style: .quiet), title: viewModel.localizedStrings.aboutExperimentButtonTitle) {
                viewModel.didTapAboutExperiment?()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

