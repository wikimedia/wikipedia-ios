import SwiftUI

struct WMFPriceButton: View {
    
    public struct Configuration {

        let currencyCode: String
        let canDeselect: Bool
        let accessibilityHint: String
        
        internal init(currencyCode: String, canDeselect: Bool = true, accessibilityHint: String) {
            self.currencyCode = currencyCode
            self.canDeselect = canDeselect
            self.accessibilityHint = accessibilityHint
        }
    }
    
    let configuration: Configuration
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding var amount: Decimal
    @Binding var isSelected: Bool
    
    var loggingTapAction: () -> Void
    
    var body: some View {
        Button {
            if !configuration.canDeselect {
                if !isSelected {
                    isSelected.toggle()
                }
            } else {
                isSelected.toggle()
            }
            loggingTapAction()
        } label: {
            Text(displayAmount ?? "")
                .font(Font(WMFFont.for(.mediumSubheadline)))
                .frame(maxWidth: .infinity)
                .padding([.top, .bottom], 13)
                .foregroundColor(isSelected ? Color(WMFColor.white) : Color(appEnvironment.theme.text))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(appEnvironment.theme.link) : Color(appEnvironment.theme.baseBackground), lineWidth: 1)
                )
        }
        .background(isSelected ? Color(appEnvironment.theme.link) : Color(appEnvironment.theme.midBackground))
        .cornerRadius(8)
        .accessibilityHint(configuration.accessibilityHint)
        .accessibilityAddTraits( isSelected ? [.isSelected] : [])
    }
    
    private var displayAmount: String? {
        let shortCurrencyFormatter = NumberFormatter.wmfShortCurrencyFormatter
        shortCurrencyFormatter.currencyCode = configuration.currencyCode
        return shortCurrencyFormatter.string(from: amount as NSNumber)
    }
}
