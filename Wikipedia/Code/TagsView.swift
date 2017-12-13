public class TagsView: SizeThatFitsView {
    var buttons: [UIButton] = []
    fileprivate var needsSubviews = false
    
    public var tags: [ReadingList] = [] {
        didSet {
            needsSubviews = true
        }
    }
    
    public override var frame: CGRect {
        didSet {
            setNeedsLayout()
        }
    }
    
    fileprivate let minButtonWidth: CGFloat = 26
    var maximumWidth: CGFloat = 0
    var buttonWidth: CGFloat  = 0
    
    fileprivate func createSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        var maxButtonWidth: CGFloat = 100
        
        for (index, tag) in tags.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(tag.name?.uppercased(), for: .normal)
            button.titleLabel?.numberOfLines = 1
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
            button.backgroundColor = UIColor.blue
            button.tag = index
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            maxButtonWidth = min(maxButtonWidth, button.intrinsicContentSize.width)
            insertSubview(button, at: 0)
            buttons.append(button)
        }
        buttonWidth = max(minButtonWidth, maxButtonWidth)
        maximumWidth = buttonWidth * CGFloat(subviews.count)
        setNeedsLayout()
    }
    
    @objc fileprivate func buttonPressed(_ sender: UIButton) {
        print("buttonPressed")
    }
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        var height: CGFloat = 0
        if apply {
            if size.width > 0 && needsSubviews {
                createSubviews()
                needsSubviews = false
            }
            let numberOfButtons = CGFloat(subviews.count)
            let buttonDelta = (min(size.width, maximumWidth) / numberOfButtons) + 5
            var x: CGFloat = 0
            for button in buttons {
                button.frame = CGRect(x: x, y: 0, width: buttonWidth, height: button.intrinsicContentSize.height)
                x += buttonDelta
                height = button.intrinsicContentSize.height
            }
        }
        return CGSize(width: maximumWidth, height: height)
        
    }
}
