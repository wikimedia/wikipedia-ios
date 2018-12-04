class TextFormattingCustomViewTableViewCell: TextFormattingTableViewCell {
    private var customView: (UIView & Themeable)?

    func configure(with customView: UIView & Themeable) {
        customView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(customView)

        let topConstraint = customView.topAnchor.constraint(equalTo: topSeparator.bottomAnchor)
        let trailingConstraint = customView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottomConstraint = customView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leadingConstraint = customView.leadingAnchor.constraint(equalTo: leadingAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            trailingConstraint,
            bottomConstraint,
            leadingConstraint
        ])

        self.customView = customView
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        customView?.apply(theme: theme)
    }
}
