import Foundation
import UIKit

protocol Card: UIContentConfiguration {
    associatedtype Payload
    
    var cardPayload: Payload { get }
    var ID: Int { get }
}

final class LocationCard: Card {
    struct Props {
        let locationName: String?
        let location: String
    }
    
    var cardPayload: Props
    var ID: Int
    
    init(cardPayload: Props, ID: Int) {
        self.cardPayload = cardPayload
        self.ID = ID
    }
}

extension LocationCard {
    func makeContentView() -> UIView & UIContentView {
        LocationCardView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        self
    }
}

final class LocationCardView: UIView & UIContentView {
    let name = UILabel.headline
    let subtitle = UILabel.subheadline.multiline()
    
    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration: configuration)
        }
    }
    
    init(configuration: LocationCard) {
        self.configuration = configuration
        super.init(frame: .zero)
        addSubview(name)
        addSubview(subtitle)
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? LocationCard else { return }
        if let locationName = configuration.cardPayload.locationName {
            name.text = locationName
        } else {
            name.text = "Unknown location"
        }
        subtitle.text = configuration.cardPayload.location
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: topAnchor, constant: .margin),
            name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .margin4),
            name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.margin4),
        ])
        NSLayoutConstraint.activate([
            subtitle.topAnchor.constraint(equalTo: name.bottomAnchor, constant: .margin2),
            subtitle.leadingAnchor.constraint(equalTo: name.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: name.trailingAnchor),
            subtitle.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
