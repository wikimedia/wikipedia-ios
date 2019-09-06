import UIKit

protocol PageViewControllerViewLifecycleDelegate: AnyObject {
    func pageViewControllerDidAppear(_ pageViewController: UIPageViewController)
}

final class WelcomePageViewController: UIPageViewController {
    weak var viewLifecycleDelegate: PageViewControllerViewLifecycleDelegate?

    private let allViewControllers: [UIViewController]

    private lazy var pageControl: UIPageControl? = {
        return view.wmf_firstSubviewOfType(UIPageControl.self)
    }()

    private let skipButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let buttonHeight: CGFloat = 40
    private let buttonHorizontalSpacing: CGFloat = 10
    private let buttonXOffset: CGFloat = 88

    private var theme = Theme.standard

    required init(viewControllers: [UIViewController]) {
        allViewControllers = viewControllers
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        dataSource = self
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(allViewControllers.count >= 2, "Expected allViewControllers to contain at least 2 elements")
        if let firstViewController = allViewControllers.first {
            setViewControllers([firstViewController], direction: direction, animated: true)
            if let viewLifecycleDelegate = firstViewController as? PageViewControllerViewLifecycleDelegate {
                self.viewLifecycleDelegate = viewLifecycleDelegate
            }
        }
        addPageControlButtons()
        updateFonts()
        apply(theme: theme)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewLifecycleDelegate?.pageViewControllerDidAppear(self)
    }

    private func addPageControlButtons() {
        addSkipButton()
        addNextButton()
    }

    private func addNextButton() {
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setTitle(CommonStrings.nextTitle, for: .normal)
        nextButton.titleLabel?.numberOfLines = 1
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        view.addSubview(nextButton)
        let heightConstraint = nextButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        let bottomConstraint = nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let leadingConstraint = nextButton.leadingAnchor.constraint(lessThanOrEqualTo: view.centerXAnchor, constant: buttonXOffset)
        let trailingConstraint = nextButton.trailingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: buttonHorizontalSpacing)
        NSLayoutConstraint.activate([
            heightConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }

    private func addSkipButton() {
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle(CommonStrings.skipTitle, for: .normal)
        skipButton.titleLabel?.numberOfLines = 1
        skipButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
        view.addSubview(skipButton)
        let heightConstraint = skipButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        let bottomConstraint = skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let leadingConstraint = skipButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: buttonHorizontalSpacing)
        let trailingConstraint = skipButton.trailingAnchor.constraint(lessThanOrEqualTo: view.centerXAnchor, constant: -buttonXOffset)
        NSLayoutConstraint.activate([
            heightConstraint,
            bottomConstraint,
            leadingConstraint,
            trailingConstraint
        ])
    }

    @objc private func next(_ sender: UIButton) {
        guard
            let visibleViewController = visibleViewController,
            let nextViewController = viewController(after: visibleViewController)
        else {
            return
        }
        view.isUserInteractionEnabled = false
        animatePageControlButtons(for: nextViewController)
        setViewControllers([nextViewController], direction: direction, animated: true) { _ in
            self.view.isUserInteractionEnabled = true
        }
    }

    @objc private func skip(_ sender: UIButton) {
        dismiss(animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        let buttonFont = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        nextButton.titleLabel?.font = buttonFont
        skipButton.titleLabel?.font = buttonFont
    }

    private var direction: UIPageViewController.NavigationDirection {
        return UIApplication.shared.wmf_isRTL ? .reverse : .forward
    }

    private func viewController(at index: Int) -> UIViewController? {
        guard index >= 0, allViewControllers.count > index else {
            return nil
        }
        return allViewControllers[index]
    }

    private var visibleViewController: UIViewController? {
        return viewControllers?.first
    }
}

extension WelcomePageViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        allViewControllers.forEach { ($0 as? Themeable)?.apply(theme: theme) }
        view.backgroundColor = theme.colors.midBackground
        pageControl?.pageIndicatorTintColor = theme.colors.pageIndicator
        pageControl?.currentPageIndicatorTintColor = theme.colors.pageIndicatorCurrent
        nextButton.tintColor = theme.colors.link
        skipButton.tintColor = UIColor(0xA2A9B1)
        nextButton.setTitleColor(theme.colors.disabledText, for: .disabled)
    }
}

extension WelcomePageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = allViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let beforeIndex = index - 1
        return self.viewController(at: beforeIndex)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return self.viewController(after: viewController)
    }

    private func viewController(after viewController: UIViewController) -> UIViewController? {
        guard let index = allViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        let afterIndex = index + 1
        return self.viewController(at: afterIndex)
    }
}

extension WelcomePageViewController: UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return allViewControllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard
            let visibleViewController = pageViewController.viewControllers?.first,
            let presentationIndex = allViewControllers.firstIndex(of: visibleViewController)
        else {
            return 0
        }
        return presentationIndex
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        let index = presentationIndex(for: pageViewController)
        guard let viewController = self.viewController(at: index) else {
            return
        }
        animatePageControlButtons(for: viewController)
    }

    private func animatePageControlButtons(for viewController: UIViewController) {
        let index = allViewControllers.firstIndex(of: viewController)
        let isLast = allViewControllers.count - 1 == index
        let alpha: CGFloat = isLast ? 0 : 1
        nextButton.isEnabled = !isLast
        guard pageControl?.alpha != alpha else {
            return
        }
        UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
            self.skipButton.alpha = alpha
            self.nextButton.alpha = alpha
            self.pageControl?.alpha = alpha
        }.startAnimation()
    }
}
