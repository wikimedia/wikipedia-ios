import SwiftUI

struct ApplePayDefaultOptionButton: View {
    let amount: Decimal
    @SwiftUI.Binding var totalDisplayAmount: String
    @SwiftUI.Binding var totalAmount: Decimal
    @SwiftUI.Binding var transactionFee: Decimal
    
    private var isSelected: Bool {
        totalAmount == amount + transactionFee
    }
    
    private var displayAmountShort: String {
        return ApplePayFormatters.currencyFormatterShort.string(from: amount as NSNumber) ?? ""
    }
    
    private var displayAmount: String {
        return ApplePayFormatters.currencyFormatter.string(from: amount as NSNumber) ?? ""
    }
    
    var body: some View {
        Button {
            let proposedTotalAmount = amount + transactionFee
            if let newTotalDisplayAmount = ApplePayFormatters.currencyFormatter.string(from: proposedTotalAmount as NSNumber),
               let newTotalAmount = ApplePayFormatters.currencyFormatter.number(from: newTotalDisplayAmount) {
                totalAmount = newTotalAmount.decimalValue
                totalDisplayAmount = newTotalDisplayAmount
            }
        } label: {
            Text(displayAmountShort)
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding([.top, .bottom], 13)
                .foregroundColor(isSelected ? Color.white : .base10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 200/255, green: 204/255, blue: 209/255), lineWidth: 1)
                )
        }
        .background(isSelected ? Color.selectedBlue : .white)
        .cornerRadius(8)
    }
}

struct ApplePayFormatters {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currencyCode
        formatter.locale = Locale.current
        return formatter
    }()
    
    static let currencyFormatterShort: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currencyCode
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

struct ApplePayUtilities {
    static func containerPaddingForHorizontalSizeClass(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 64 : 16
    }
    
    static var initialAmount: Decimal {
        return ApplePayFormatters.currencyFormatter.number(from: "0")?.decimalValue ?? 0.00
    }
    
    static var initialDisplayAmount: String {
        return ApplePayFormatters.currencyFormatter.string(from: initialAmount as NSNumber) ?? "0"
    }
    
    static var currencySymbolIsLeading: Bool {
        
        guard let symbol = ApplePayFormatters.currencyFormatter.currencySymbol else {
            return false
        }
        
        let range = (Self.initialDisplayAmount as NSString).range(of: symbol)
        
        guard range.location == 0 else {
            return false
        }
        
        return true
    }
}

extension Color {
    static let base10 = Color(red: 32/255, green: 33/255, blue: 34/255)
    static let selectedBlue = Color(red: 51/255, green: 102/255, blue: 204/255)
    static let divColor = Color(red: 162/255, green: 169/255, blue: 177/255)
}

struct ApplePayDefaultOptionsView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.sizeCategory) var contentSizeCategory
    
    let amounts: [Decimal]
    @SwiftUI.Binding var totalDisplayAmount: String
    @SwiftUI.Binding var totalAmount: Decimal
    @SwiftUI.Binding var transactionFee: Decimal
    
    private var shouldDisplayVertically: Bool {
        return horizontalSizeClass == .compact && (contentSizeCategory == .accessibilityLarge ||
                                                   contentSizeCategory == .accessibilityExtraLarge ||
                                                   contentSizeCategory == .accessibilityExtraExtraLarge ||
                                                   contentSizeCategory == .accessibilityExtraExtraExtraLarge)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            if shouldDisplayVertically {
                ForEach(amounts, id: \.self) { amount in
                    ApplePayDefaultOptionButton(amount: amount, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount, transactionFee: $transactionFee)
                }
            } else {
                HStack(spacing: 9) {
                    let firstThreeAmounts = amounts.prefix(3)
                    ForEach(firstThreeAmounts, id: \.self) { amount in
                        ApplePayDefaultOptionButton(amount: amount, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount, transactionFee: $transactionFee)
                    }
                }
                HStack(spacing: 9) {
                    let lastFourAmounts = amounts.suffix(4)
                    ForEach(lastFourAmounts, id: \.self) { amount in
                        ApplePayDefaultOptionButton(amount: amount, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount, transactionFee: $transactionFee)
                    }
                }
            }
            
        }
    }
}

struct ApplePayCheckmarkView: View {
    
    var checked: Bool
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundColor(checked ? .selectedBlue : Color.secondary)
                    .offset(x: 0, y: 1.5)
            Text(text)
                .font(Font.subheadline)
                .foregroundColor(.base10)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ApplePayTransactionFeeView: View {
    @Binding var checked: Bool
    @Binding var transactionFee: Decimal
    let text: String
    let maxTransactionFee: Decimal
    
    @SwiftUI.Binding var totalDisplayAmount: String
    @SwiftUI.Binding var totalAmount: Decimal
    
    var body: some View {
        ApplePayCheckmarkView(checked: checked, text: text)
        .onTapGesture {
            self.checked.toggle()
            if checked {
                transactionFee = maxTransactionFee
                totalAmount = totalAmount + transactionFee
            } else {
                totalAmount = totalAmount - transactionFee
                transactionFee = 0
            }
            
            if let newTotalDisplayAmount = ApplePayFormatters.currencyFormatter.string(from: totalAmount as NSNumber) {
                totalDisplayAmount = newTotalDisplayAmount
            }
        }
    }
}

struct ApplePayTappableCheckmarkView: View {
    
    @Binding var checked: Bool
    let text: String
    
    var body: some View {
        ApplePayCheckmarkView(checked: checked, text: text)
        .onTapGesture {
            self.checked.toggle()
        }
    }
}

struct ApplePayCheckmarkStackView: View {
    
    @Binding var canAddTransactionFee: Bool
    @Binding var canSendMeEmail: Bool
    
    @Binding var transactionFee: Decimal
    let maxTransactionFee: Decimal
    
    @SwiftUI.Binding var totalDisplayAmount: String
    @SwiftUI.Binding var totalAmount: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ApplePayTransactionFeeView(checked: $canAddTransactionFee, transactionFee: $transactionFee, text: "I’ll generously add $2 to cover the transaction fees so you can keep 100% of my donation.", maxTransactionFee: maxTransactionFee, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount)
            ApplePayTappableCheckmarkView(checked: $canSendMeEmail, text: "Yes, the Wikimedia Foundation can send me an occasional email.")
        }
        
    }
}

struct ApplePayDonateView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @SwiftUI.State private var totalDisplayAmount: String = ApplePayUtilities.initialDisplayAmount
    @SwiftUI.State private var totalAmount: Decimal = ApplePayUtilities.initialAmount
    
    @SwiftUI.State private var canAddTransactionFee = false
    @SwiftUI.State private var canSendMeEmail = false
    
    private let paymentHandler = ApplePayPaymentHandler()
    
    // TODO: pull in from external json file
    private let defaultOptionAmounts: [Decimal] = [10, 20, 30, 50, 100, 300, 500]
    let maxTransactionFee = Decimal(2)
    @SwiftUI.State private var transactionFee: Decimal = 0
    
    var sizeClassDonateButtonPadding: CGFloat {
        horizontalSizeClass == .regular ? 120 : 32
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ApplePayDefaultOptionsView(amounts: defaultOptionAmounts, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount, transactionFee: $transactionFee)
            Spacer()
                .frame(height: 32)
            ApplePayTextField(totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount, scrubAmount: scrubAmount)
            Spacer()
                .frame(height: 16)
            Divider()
                .background(Color.divColor)
            Spacer()
                .frame(height: 12)
            ApplePayCheckmarkStackView(canAddTransactionFee: $canAddTransactionFee, canSendMeEmail: $canSendMeEmail, transactionFee: $transactionFee, maxTransactionFee: maxTransactionFee, totalDisplayAmount: $totalDisplayAmount, totalAmount: $totalAmount)
            Spacer()
                .frame(height: 24)
            ApplePayDonateButton(needsSetup: ApplePayPaymentHandler.needsSetup)
                .onTapGesture {
                    scrubAmount()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    paymentHandler.startPayment(amount: totalAmount) { success in
                        print(success)
                    }
                }
                .frame(height: 40)
                .padding([.leading, .trailing], sizeClassDonateButtonPadding)


        }
        .padding([.leading, .trailing], ApplePayUtilities.containerPaddingForHorizontalSizeClass(horizontalSizeClass))
        .padding([.top, .bottom], 28)
        .background(Color(red: 248/255, green: 249/255, blue: 250/255))
    }
    
    private func scrubAmount() {
        
        if !totalDisplayAmount.contains(ApplePayFormatters.currencyFormatter.currencySymbol) {
            if ApplePayUtilities.currencySymbolIsLeading {
                totalDisplayAmount = ApplePayFormatters.currencyFormatter.currencySymbol + totalDisplayAmount
            } else {
                totalDisplayAmount.append(ApplePayFormatters.currencyFormatter.currencySymbol)
            }
        }
        
        guard let newTotalAmount = ApplePayFormatters.currencyFormatter.number(from: totalDisplayAmount),
              let newTotalDisplayAmount = ApplePayFormatters.currencyFormatter.string(from: newTotalAmount) else {
            
            // TODO: maybe display an error instead of resetting to 0
            if totalDisplayAmount != ApplePayUtilities.initialDisplayAmount || totalAmount != ApplePayUtilities.initialAmount {
                totalDisplayAmount = ApplePayUtilities.initialDisplayAmount
                totalAmount = ApplePayUtilities.initialAmount
                canAddTransactionFee = false
            }
            return
        }
        
        if totalDisplayAmount != newTotalDisplayAmount || totalAmount != newTotalAmount.decimalValue {
            totalDisplayAmount = newTotalDisplayAmount
            totalAmount = newTotalAmount.decimalValue
        }
    }
}

struct ApplePayFooterItemView: View {
    
    let text: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button {
                print("asdsf")
            } label: {
                Text(text)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.selectedBlue)
            }
            Spacer()
        }
    }
}

struct ApplePayFooterView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ApplePayFooterItemView(text: "Donate Via the Web") {
                print("")
            }
            ApplePayFooterItemView(text: "Problems donating?") {
                print("")
            }
            ApplePayFooterItemView(text: "Other ways to give") {
                print("")
            }
            ApplePayFooterItemView(text: "Frequently asked questions") {
                print("")
            }
            ApplePayFooterItemView(text: "Tax deductability information") {
                print("")
            }
        }
        .padding(EdgeInsets(top: 16, leading: 0, bottom: 28, trailing: 0))
    }
}

struct ApplePayContentView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            ApplePayDonateView()
            ApplePayFooterView()
                .padding([.leading, .trailing], ApplePayUtilities.containerPaddingForHorizontalSizeClass(horizontalSizeClass))
            
        }
    }
}

extension ApplePayContentView: NavBarKeyboardDismissable {
    
}

struct ApplePayContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView(.vertical, showsIndicators: true) {
                ApplePayContentView()
            }
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 mini"))
            .previewDisplayName("iPhone 13 mini")
            
            ScrollView(.vertical, showsIndicators: true) {
                ApplePayContentView()
            }
            .environment(\.sizeCategory, .large)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
            .previewDisplayName("iPhone SE")
            
            if #available(iOS 15.0, *) {
                ScrollView(.vertical, showsIndicators: true) {
                    ApplePayContentView()
                }
                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
                .previewDevice(PreviewDevice(rawValue: "iPad 2"))
                .previewDisplayName("iPad Pro (12.9-inch)")
                .previewInterfaceOrientation(.portraitUpsideDown)
            } else {
                // Fallback on earlier versions
            }
            
            if #available(iOS 15.0, *) {
                ScrollView(.vertical, showsIndicators: true) {
                    ApplePayContentView()
                }
                .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
                .previewDisplayName("iPhone 13 Pro Max (landscape)")
                .previewInterfaceOrientation(.landscapeLeft)
            } else {
                // Fallback on earlier versions
            }
                                 

        }
    }
}
