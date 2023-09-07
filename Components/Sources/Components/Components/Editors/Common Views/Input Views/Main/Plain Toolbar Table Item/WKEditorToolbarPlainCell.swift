
import Foundation
import UIKit

class WKEditorToolbarPlainCell: UITableViewCell {
    
    // MARK: - Properties
    
    private lazy var componentView: WKEditorToolbarPlainView = {
        let view = UINib(nibName: String(describing: WKEditorToolbarPlainView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKEditorToolbarPlainView
        
        return view
    }()
    
    var delegate: WKEditorInputViewDelegate? {
        get {
            return componentView.delegate
        }
        set {
            componentView.delegate = newValue
        }
    }
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(componentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: componentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: componentView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: componentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: componentView.bottomAnchor)
        ])
    }
}
