import UIKit

public class LabelGroupAccessibilityElement: UIAccessibilityElement {
    let labels: [UILabel]
    weak var view: UIView?
    
    public init(view: UIView, labels: [UILabel]) {
        self.labels = labels
        self.view = view
        super.init(accessibilityContainer: view)
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitLink
        update()
    }
    
    func update() {
        guard let firstLabel = labels.first else {
            return
        }
        var combinedLabel: String = ""
        if let accessibilityLabel = firstLabel.accessibilityLabel {
            combinedLabel = accessibilityLabel
        } else if let text = firstLabel.text {
            combinedLabel = text
        }
        var combinedFrame = firstLabel.frame
        for label in labels[1..<labels.count] {
            combinedFrame = combinedFrame.union(label.frame)
            var maybeLabelLine: String? = label.accessibilityLabel
            if maybeLabelLine == nil {
                maybeLabelLine = label.text
            }
            if let labelLine: String = maybeLabelLine, (labelLine as NSString).length > 0 {
                combinedLabel = "\(combinedLabel)\n\(labelLine)"
            }
        }
        if #available(iOS 10.0, *) {
            self.accessibilityFrameInContainerSpace = combinedFrame
        } else {
            self.accessibilityFrame = view?.convert(combinedFrame, to: nil) ?? CGRect.zero
        }
        self.accessibilityLabel = combinedLabel
    }
}
