
import Foundation
import UIKit

class WKEditorDestructiveCell: UITableViewCell {
    
    //MARK: - Properties
    
    private lazy var componentView: WKEditorDestructiveView = {
       let view = WKEditorDestructiveView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //MARK: - Lifecycle
    
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
    
    //MARK: - Internal
    
    func configure(viewModel: WKEditorDestructiveViewModel) {
        componentView.configure(viewModel: viewModel)
    }
}
