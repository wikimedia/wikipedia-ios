import UIKit
import Combine

/// A banner that tells the user that the app uses a temporary account.
///
/// The login and account creation screens add this view under the navigation bar.
/// It is a plain UIKit view, so it does not react to the keyboard on those screens.
public final class WMFTempAccountsToastView: UIView {

    // MARK: - Nested Types

    private enum Layout {
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let iconSize: CGFloat = 16
        static let iconSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 46
        static let buttonHorizontalPadding: CGFloat = 16
        static let lineSpacing: CGFloat = 3
    }

    // MARK: - Properties

    private let viewModel: WMFTempAccountsToastViewModel
    private var cancellables = Set<AnyCancellable>()

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let readMoreButton = UIButton(type: .system)
    private let divider = UIView()

    private var theme: WMFTheme { WMFAppEnvironment.current.theme }

    // MARK: - Lifecycle

    public init(viewModel: WMFTempAccountsToastViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        applyTheme()

        WMFAppEnvironment.publisher
            .sink { [weak self] _ in self?.applyTheme() }
            .store(in: &cancellables)

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: Self, _) in
            view.applyText()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported. Use init(viewModel:).")
    }

    // MARK: - Setup

    private func setupViews() {
        iconImageView.image = WMFIcon.exclamationPointCircle?.withRenderingMode(.alwaysTemplate)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isAccessibilityElement = false

        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        readMoreButton.translatesAutoresizingMaskIntoConstraints = false
        readMoreButton.addTarget(self, action: #selector(didTapReadMore), for: .touchUpInside)

        divider.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(readMoreButton)
        addSubview(divider)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topPadding),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            iconImageView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Layout.topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: Layout.iconSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),

            readMoreButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            readMoreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),
            readMoreButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            divider.topAnchor.constraint(equalTo: readMoreButton.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyText()
    }

    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(
            font: WMFFont.for(.callout),
            boldFont: WMFFont.for(.boldCallout),
            italicsFont: WMFFont.for(.italicCallout),
            boldItalicsFont: WMFFont.for(.boldItalicCallout),
            color: theme.text,
            linkColor: theme.link,
            lineSpacing: Layout.lineSpacing
        )
    }

    /// Builds the attributed title from the HTML string. Call this again when the font size or the theme changes.
    private func applyText() {
        let attributedTitle = (try? HtmlUtils.nsAttributedStringFromHtml(viewModel.title, styles: titleStyles))
            ?? NSAttributedString(string: viewModel.title)
        titleLabel.attributedText = attributedTitle

        // This matches the quiet style of WMFSmallButton: link color, body font, no background.
        var configuration = UIButton.Configuration.plain()
        configuration.title = viewModel.readMoreButtonTitle
        configuration.baseForegroundColor = theme.link
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Layout.buttonHorizontalPadding, bottom: 0, trailing: Layout.buttonHorizontalPadding)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = WMFFont.for(.body)
            return attributes
        }
        readMoreButton.configuration = configuration
    }

    private func applyTheme() {
        backgroundColor = theme.midBackground
        iconImageView.tintColor = theme.text
        divider.backgroundColor = theme.border
        applyText()
    }

    // MARK: - Actions

    @objc private func didTapReadMore() {
        viewModel.didTapReadMore()
    }
}
