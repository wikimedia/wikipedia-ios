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

final class InputCardView: UITextField & UIContentView {
    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration: configuration)
        }
    }
    
    init(configuration initialConfiguration: InputCard) {
        self.configuration = initialConfiguration
        super.init(frame: .zero)
        textContentType = .location
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? InputCard else { return }
        text = configuration.cardPayload.location
    }
}

final class InputCardPresenter {
    
    typealias Dependencies = OpenLocationServiceProvider
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func handleLocation(_ locationString: String?) {
    }
}
