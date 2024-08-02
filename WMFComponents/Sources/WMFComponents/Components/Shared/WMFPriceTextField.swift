import SwiftUI

struct WMFPriceTextField: View {
    
    struct Configuration {
        let currencyCode: String
        let focusOnAppearance: Bool
        let doneTitle: String
        let textfieldAccessibilityHint: String
        let doneAccessibilityHint: String
    }
    
    let configuration: Configuration
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding var amount: Decimal
    @Binding var hasFocus: Bool // Set to programmatically change focus outside of view
    
    @FocusState private var isFocused: Bool
    @AccessibilityFocusState var accessibilityFocus: Bool
 
    var body: some View {
        TextField("", value: $amount, format: .currency(code: configuration.currencyCode))
            .keyboardType(.decimalPad)
            .font(Font(WMFFont.for(.boldTitle1)))
            .foregroundColor(Color(appEnvironment.theme.text))
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(appEnvironment.theme.baseBackground), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(appEnvironment.theme.midBackground)))
                )
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .accessibilityHint(configuration.textfieldAccessibilityHint)
            .focused($isFocused)
            .accessibilityFocused($accessibilityFocus)
            .onChange(of: hasFocus) {
                isFocused = $0
                accessibilityFocus = $0
            }
            .onChange(of: isFocused) {
                hasFocus = $0
                accessibilityFocus = $0
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(configuration.doneTitle) {
                        isFocused = false
                        // Immediately highlight textfield with VoiceOver, so user can confirm what they entered.
                        accessibilityFocus = true
                    }
                    .foregroundColor(Color(appEnvironment.theme.link))
                    .font(Font(WMFFont.for(.headline)))
                    .accessibilityHint(configuration.doneAccessibilityHint)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if configuration.focusOnAppearance {
                        isFocused = true
                    }
                }
            }
    }
}
