import SwiftUI

struct ApplePayTextField: View {
    @SwiftUI.Binding var totalDisplayAmount: String
    @SwiftUI.Binding var totalAmount: Decimal
    
    let scrubAmount: () -> Void

    var body: some View {
        TextField("", text: $totalDisplayAmount, onEditingChanged: onEditingChanged(_:))
        .foregroundColor(.base10)
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .keyboardType(.decimalPad)
        .font(Font.title.weight(.semibold))
    }

    func onEditingChanged(_ isEditing: Bool) {
        if isEditing {
            NotificationCenter.default.post(name: .swiftUITextfieldDidBeginEditing, object: nil)
        } else {
            scrubAmount()
            NotificationCenter.default.post(name: .swiftUITextfieldDidEndEditing, object: nil)
        }
    }
}

struct ApplePayTextField_Previews: PreviewProvider {
    
    static var previews: some View {
        ApplePayTextField(totalDisplayAmount: .constant("$0.00"), totalAmount: .constant(0.00), scrubAmount: { })
    }
}
