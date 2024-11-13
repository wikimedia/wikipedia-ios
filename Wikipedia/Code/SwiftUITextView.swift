import WMFComponents
import SwiftUI

struct TextView: UIViewRepresentable {
    
    let placeholder: String
    let theme: Theme
    @Binding var text: String
    
    typealias UIViewType = SwiftUITextView
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIViewType {
        let textView = UIViewType()
        textView.setup(placeholder: placeholder, theme: theme)
        textView.delegate = context.coordinator
        let font = WMFFont.for(.callout, compatibleWith: textView.traitCollection)
        textView.font = font
        textView.placeholderLabel.font = font
        return textView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, placeholder: placeholder)
    }
    
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<Self>) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        
        @Binding var text: String
        let placeholder: String
        
        init(text: Binding<String>, placeholder: String) {
            _text = text
            self.placeholder = placeholder
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

/// A text view with separated placeholder label and keyboad Done input accessory view. Designed to be embedded in SwiftUI.
class SwiftUITextView: UITextView {
    
    private var theme = Theme.standard
    private var placeholder: String?
    
    lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .natural
        return label
    }()
    
    override var text: String! {
        get {
            return super.text
        }
        set {
            super.text = newValue
            placeholderLabel.isHidden = !newValue.isEmpty
        }
    }
    
    func setup(placeholder: String, theme: Theme) {
        self.placeholder = placeholder
        self.theme = theme
        
        // remove padding
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        
        placeholderLabel.text = placeholder
        
        addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor),
            placeholderLabel.widthAnchor.constraint(equalTo: widthAnchor)
        ])
        
        setDoneOnKeyboard()
        
        apply(theme: theme)
    }
    
    func setDoneOnKeyboard() {
        let keyboardToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        keyboardToolbar.barStyle = .default
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tappedDone))
        doneBarButton.tintColor = theme.colors.link
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        self.inputAccessoryView = keyboardToolbar
    }

    @objc func tappedDone() {
        self.resignFirstResponder()
    }
}

extension SwiftUITextView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        textColor = theme.colors.primaryText
        placeholderLabel.textColor = theme.colors.secondaryText
        keyboardAppearance = theme.keyboardAppearance
    }
}
