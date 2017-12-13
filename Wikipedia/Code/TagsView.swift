public class TagsView: SizeThatFitsView {
    var buttons: [UIButton] = []
    fileprivate var needsSubviews = true
    
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
    fileprivate let maxButtonWidth: CGFloat = 100
    var maximumWidth: CGFloat = 0
    var buttonWidth: CGFloat  = 0
    
    fileprivate func createSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        for (index, tag) in tags.enumerated() {
            guard index != 3 else {
                return
            }
            let button = UIButton(type: .custom)
            let title = index == 2 ? "+ \(tags.count - index)" : tag.name?.uppercased()
            button.setTitle(title, for: .normal)
            button.titleLabel?.numberOfLines = 1
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.contentEdgeInsets = UIEdgeInsetsMake(6, 6, 6, 6)
            button.backgroundColor = UIColor.blue
            button.tag = index
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            maximumWidth += min(maxButtonWidth, button.intrinsicContentSize.width)
            insertSubview(button, at: 0)
            buttons.append(button)
        }
        setNeedsLayout()
    }
    
    @objc fileprivate func buttonPressed(_ sender: UIButton) {
        let readingList = tags[sender.tag]
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
                button.frame = CGRect(x: x, y: 0, width: min(maxButtonWidth, button.intrinsicContentSize.width), height: button.intrinsicContentSize.height)
                x += buttonDelta
                height = button.intrinsicContentSize.height
            }
        }
        return CGSize(width: maximumWidth, height: height)
        
    }
}
