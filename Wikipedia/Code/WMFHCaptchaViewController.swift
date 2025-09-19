import UIKit
import HCaptcha
import WebKit

class WMFHCaptchaViewController: UIViewController {

    struct Constants {
        static let webViewTag = 123
    }

    // MARK: - UI Elements
    let captchaContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    let localeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Default", "Chinese"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    let validateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Validate", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - HCaptcha
    var hcaptcha: HCaptcha!
    var locale: Locale?
    private var challengeShown = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupLayout()
        setupActions()
        setupHCaptchaIfNeeded()
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(captchaContainer)

        // Bottom controls
        view.addSubview(label)
        view.addSubview(spinner)
        view.addSubview(localeSegmentedControl)

        let buttonStack = UIStackView(arrangedSubviews: [validateButton, stopButton, resetButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // MARK: Constraints

        // HCaptcha container at top
        NSLayoutConstraint.activate([
            captchaContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captchaContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captchaContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captchaContainer.bottomAnchor.constraint(equalTo: localeSegmentedControl.topAnchor, constant: -20)
        ])

        // Locale segmented control pinned above buttons
        NSLayoutConstraint.activate([
            localeSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            localeSegmentedControl.bottomAnchor.constraint(equalTo: validateButton.topAnchor, constant: -20),
            localeSegmentedControl.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])

        // Label and spinner above segmented control
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: localeSegmentedControl.topAnchor, constant: -40),
            spinner.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
        ])

        // Button stack pinned to bottom
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        localeSegmentedControl.addTarget(self, action: #selector(didPressLocaleSegmentedControl(_:)), for: .valueChanged)
        stopButton.addTarget(self, action: #selector(didPressStopButton(_:)), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(didPressResetButton(_:)), for: .touchUpInside)
        validateButton.addTarget(self, action: #selector(didPressValidateButton(_:)), for: .touchUpInside)
    }

    private func bringControlsToFront() {
        view.bringSubviewToFront(label)
        view.bringSubviewToFront(spinner)
        view.bringSubviewToFront(localeSegmentedControl)
        view.bringSubviewToFront(validateButton)
        view.bringSubviewToFront(stopButton)
        view.bringSubviewToFront(resetButton)
    }

    @objc private func didPressLocaleSegmentedControl(_ sender: UISegmentedControl) {
        label.text = ""
        switch sender.selectedSegmentIndex {
        case 0: locale = nil
        case 1: locale = Locale(identifier: "zh-CN")
        default: assertionFailure("invalid index")
        }
        setupHCaptchaIfNeeded()
    }

    @objc private func didPressStopButton(_ sender: UIButton) {
        hcaptcha.stop()
        spinner.stopAnimating()
    }

    @objc private func didPressResetButton(_ sender: UIButton) {
        hcaptcha.reset()
        label.text = ""
        spinner.stopAnimating()
    }

    @objc private func didPressValidateButton(_ sender: UIButton) {
        spinner.startAnimating()
        label.text = ""

        hcaptcha.validate(on: captchaContainer) { [weak self] result in
            guard let self = self else { return }

            self.spinner.stopAnimating()

            do {
                self.label.text = try result.dematerialize()
            } catch let error as HCaptchaError {
                self.label.text = error.description
            } catch let error {
                self.label.text = String(describing: error)
            }

            if let subview = self.captchaContainer.viewWithTag(Constants.webViewTag) {
                subview.removeFromSuperview()
            }
            self.challengeShown = false
        }
    }

    // MARK: - HCaptcha Setup
    private func setupHCaptchaIfNeeded() {
        guard !Bundle.main.bundlePath.contains("Tests") else { return }

        // swiftlint:disable:next force_try
        hcaptcha = try! HCaptcha(apiKey: "45205f58-be1c-40f0-b286-07a4498ea3da",
                                 baseURL: URL(string: "https://hcaptcha.wikimedia.org")!,
                                locale: locale,
                                diagnosticLog: true)

        hcaptcha.onEvent { [weak self] event, _ in
            guard let self = self else { return }
            if event == .open {
                if let webview = self.captchaContainer.viewWithTag(Constants.webViewTag) {
                    self.moveHCaptchaUp(webview)
                }
                // Ensure buttons & controls are on top
                self.bringControlsToFront()
            }
        }

        hcaptcha.configureWebView { [weak self] webview in
            guard let self = self else { return }
            webview.frame = self.captchaContainer.bounds
            webview.tag = Constants.webViewTag
            webview.isOpaque = false
            webview.backgroundColor = .clear
            webview.scrollView.backgroundColor = .clear
            self.captchaContainer.addSubview(webview)
        }
    }

    // MARK: - Helper
    private func moveHCaptchaUp(_ webview: UIView) {
        webview.frame = captchaContainer.bounds
    }
}
