import UIKit

public class RabbitHolePresentationView: UIView {
    @IBOutlet weak var rabbitHoleView: UIView!
    @IBOutlet var contentView: UIView!

    public init(with view: UIView) {
        super.init(frame: .zero)
        commonInit()
        rabbitHoleView.wmf_addSubviewWithConstraintsToEdges(view)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed(RabbitHolePresentationView.wmf_nibName(), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}
