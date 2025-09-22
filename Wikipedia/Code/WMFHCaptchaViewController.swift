import UIKit
import HCaptcha
import WebKit
import WMF

class WMFHCaptchaViewController: ThemeableViewController {

    // MARK: - UI Elements
    let captchaContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - HCaptcha
    var hCaptcha: HCaptcha?
    var captchaWebView: WKWebView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        setupHCaptcha()
        apply(theme: theme)
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(captchaContainer)

        NSLayoutConstraint.activate([
            captchaContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captchaContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            captchaContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            captchaContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func validate() {

        hCaptcha?.validate(on: captchaContainer) { [weak self] result in
            guard let self = self else { return }

            do {
                let token = try result.dematerialize()
                print("token: \(token)")
            } catch let error as HCaptchaError {
                print("HCaptchaError: \(error.description)")
            } catch let error {
                print("error: \(error)")
            }

            for subview in self.captchaContainer.subviews {
                subview.removeFromSuperview()
            }
        }
    }

    // MARK: - HCaptcha Setup
    private func setupHCaptcha() {
        // "f1f21d64-6384-4114-b7d0-d9d23e203b4a" //don't always challenge
        // "45205f58-be1c-40f0-b286-07a4498ea3da" //always challenge
        hCaptcha = try? HCaptcha(apiKey: "f1f21d64-6384-4114-b7d0-d9d23e203b4a",
                                 baseURL: URL(string: "https://meta.wikimedia.org")!,
                                 jsSrc: URL(string:"https://assets-hcaptcha.wikimedia.org/1/api.js")!,
                                 endpoint: URL(string: "https://hcaptcha.wikimedia.org")!,
                                 reportapi: URL(string: "https://report-hcaptcha.wikimedia.org")!,
                                 assethost: URL(string: "https://assets-hcaptcha.wikimedia.org")!,
                                 imghost: URL(string: "https://imgs-hcaptcha.wikimedia.org")!,
                                 theme: theme.isDark ? "dark" : "light",
                                diagnosticLog: true)

        hCaptcha?.onEvent { [weak self] event, _ in
            guard let self = self else { return }
            if event == .open {
                print("open!")
            }
        }

        hCaptcha?.configureWebView { [weak self] webView in
            guard let self = self else { return }
            webView.frame = self.captchaContainer.bounds
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.scrollView.backgroundColor = .clear
            self.captchaContainer.addSubview(webView)
            self.captchaWebView = webView
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}
