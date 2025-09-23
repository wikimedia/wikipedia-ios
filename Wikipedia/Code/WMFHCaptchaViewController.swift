import UIKit
import HCaptcha
import WebKit
import WMF

class WMFHCaptchaViewController: ThemeableViewController {
    
    enum CustomError: Error {
        case hCaptchaInvalidURL
        case hCaptchaExpired
        case hCaptchaClosed
        case hCaptchaError
    }

    // MARK: - UI Elements
    let captchaContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let spinner: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        return activityIndicator
    }()

    // MARK: - HCaptcha
    var hCaptcha: HCaptcha?
    var captchaWebView: WKWebView?
    
    var successAction: ((String) -> Void)?
    var errorAction: ((Error) -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        spinner.startAnimating()
        setupHCaptcha()
        apply(theme: theme)
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(spinner)
        view.addSubview(captchaContainer)

        NSLayoutConstraint.activate([
            captchaContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            captchaContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            captchaContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            captchaContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            view.centerXAnchor.constraint(equalTo: spinner.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: spinner.centerYAnchor)
        ])
    }

    func validate() {

        hCaptcha?.validate(on: captchaContainer) { [weak self] result in
            guard let self = self else { return }

            spinner.stopAnimating()
            
            do {
                let token = try result.dematerialize()
                successAction?(token)
            } catch let error as HCaptchaError {
                errorAction?(error)
            } catch let error {
                errorAction?(error)
            }

            captchaWebView?.removeFromSuperview()
            captchaWebView = nil
        }
    }

    // MARK: - HCaptcha Setup
    private func setupHCaptcha() {
        do {
            // "f1f21d64-6384-4114-b7d0-d9d23e203b4a" //doesn't always challenge
            // "45205f58-be1c-40f0-b286-07a4498ea3da" //always challenge
            
            guard let baseURL = URL(string: "https://meta.wikimedia.org"),
                  let jsSrc = URL(string:"https://assets-hcaptcha.wikimedia.org/1/api.js"),
                  let endpoint = URL(string: "https://hcaptcha.wikimedia.org"),
                  let reportapi = URL(string: "https://report-hcaptcha.wikimedia.org"),
                  let assethost = URL(string: "https://assets-hcaptcha.wikimedia.org"),
                  let imghost = URL(string: "https://imgs-hcaptcha.wikimedia.org") else {
                      errorAction?(CustomError.hCaptchaInvalidURL)
                      return
                  }
            
            hCaptcha = try HCaptcha(apiKey: "45205f58-be1c-40f0-b286-07a4498ea3da",
                                     baseURL: baseURL,
                                     jsSrc: jsSrc,
                                     endpoint: endpoint,
                                     reportapi: reportapi,
                                     assethost: assethost,
                                     imghost: imghost,
                                     theme: theme.isDark ? "dark" : "light",
                                    diagnosticLog: true)
        } catch let error {
            errorAction?(error)
            return
        }
        

        hCaptcha?.onEvent { [weak self] event, _ in
            guard let self = self else { return }
            switch event {
            case .challengeExpired:
                self.errorAction?(CustomError.hCaptchaExpired)
            case .close:
                self.errorAction?(CustomError.hCaptchaClosed)
            case .error:
                self.errorAction?(CustomError.hCaptchaError)
            case .expired:
                self.errorAction?(CustomError.hCaptchaExpired)
            case .open:
                break
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let captchaWebView = captchaWebView else {
            return
        }
        
        captchaWebView.frame = self.captchaContainer.bounds
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = .black.withAlphaComponent(0.5)
    }
}
