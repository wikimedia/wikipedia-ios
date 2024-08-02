import WMFComponents

class ThreeLineHeaderView: UIView {

    let topSmallLine = UILabel()
    let middleLargeLine = UILabel()
    let bottomSmallLine = UILabel()

    init() {
        super.init(frame: .zero)
        setupView()
        updateFonts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 25
        let paddingBetweenLabels: CGFloat = 15

        topSmallLine.numberOfLines = 1
        middleLargeLine.numberOfLines = 1
        bottomSmallLine.numberOfLines = 2

        let holderView = UIView()
        [topSmallLine, middleLargeLine, bottomSmallLine].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            holderView.addSubview($0)
            $0.leadingAnchor.constraint(equalTo: holderView.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: holderView.trailingAnchor).isActive = true
        })

        NSLayoutConstraint.activate([
            topSmallLine.topAnchor.constraint(equalTo: holderView.topAnchor),
            middleLargeLine.topAnchor.constraint(equalTo: topSmallLine.bottomAnchor, constant: paddingBetweenLabels),
            bottomSmallLine.topAnchor.constraint(equalTo: middleLargeLine.bottomAnchor, constant: paddingBetweenLabels),
            bottomSmallLine.bottomAnchor.constraint(equalTo: holderView.bottomAnchor)
        ])

        wmf_addSubview(holderView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding))
    }

    private func updateFonts() {
        topSmallLine.font = WMFFont.for(.boldCaption1, compatibleWith: traitCollection)
        bottomSmallLine.font = WMFFont.for(.boldCaption1, compatibleWith: traitCollection)
        middleLargeLine.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
    }
}

extension ThreeLineHeaderView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        topSmallLine.textColor = theme.colors.secondaryText
        bottomSmallLine.textColor = theme.colors.secondaryText
        middleLargeLine.textColor = theme.colors.primaryText
    }
}
