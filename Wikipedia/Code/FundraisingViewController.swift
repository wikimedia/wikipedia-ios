import UIKit

class FundraisingViewController: ThemeableViewController, CardContent {

    func contentHeight(forWidth width: CGFloat) -> CGFloat {
//        let size = CGSize(width: width, height: UIView.noIntrinsicMetric)
//        return view.sizeThatFits(size).height
        //view.bounds.size.width = width
        var size = UIView.layoutFittingCompressedSize
        size.width = width
        return view.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
    }
}
