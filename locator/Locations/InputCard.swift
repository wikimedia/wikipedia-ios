import Foundation
import UIKit

final class InputCard: Card {
    struct Props {
        let location: String?
    }
    
    var cardPayload: Props
    var ID: Int
    fileprivate let presenter: InputCardPresenter
    
    
    init(cardPayload: Props, ID: Int, presenter: InputCardPresenter) {
        self.presenter = presenter
        self.cardPayload = cardPayload
        self.ID = ID
    }
}

extension InputCard {
    func makeContentView() -> UIView & UIContentView {
        InputCardView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        self
    }
}

final class InputCardView: UITextField & UIContentView & UITextFieldDelegate {
    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration: configuration)
        }
    }
    
    init(configuration initialConfiguration: InputCard) {
        self.configuration = initialConfiguration
        super.init(frame: .zero)
        placeholder = "location, eg: 32.123,25.345"
        text = initialConfiguration.cardPayload.location
        var buttonConfiguration = UIButton.Configuration.borderless()
        buttonConfiguration.image = .sfLocation
        buttonConfiguration.imagePlacement = .leading
        buttonConfiguration.imagePadding = .margin
        let button = UIButton(configuration: buttonConfiguration, primaryAction: UIAction() { _ in
            initialConfiguration.presenter.handleLocation(self.text)
        })
        leftView = button
        leftViewMode = .always
        keyboardType = .numbersAndPunctuation
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789., ")
        let characterSet = CharacterSet(charactersIn: string)
        guard allowedCharacters.isSuperset(of: characterSet) else {
            return false
        }
        
        // Check if the replacement text contains more than one comma or two dots
        let existingText = self.text ?? ""
        let updatedText = (existingText as NSString).replacingCharacters(in: range, with: string)
        let numbers = updatedText.components(separatedBy: ",")
        let commaCount = numbers.count - 1
        let isDoubleDot = numbers.contains { $0.components(separatedBy: ".").count > 2 }
        guard commaCount < 2, !isDoubleDot else {
            return false
        }
        
        return true
    }
    
    func configure(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? InputCard else { return }
        text = configuration.cardPayload.location
    }
}
