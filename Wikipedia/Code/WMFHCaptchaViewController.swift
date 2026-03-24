import UIKit
import HCaptcha
import WebKit
import WMF
import WMFData
import WMFTestKitchen

class WMFHCaptchaViewController: ThemeableViewController {
    
    enum CustomError: Error {
        case hCaptchaInvalidURL
        case hCaptchaExpired
        case hCaptchaClosed
        case hCaptchaError
        case hCaptchaMissingConfig
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
    
    var authInstrument: InstrumentImpl?

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
        apply(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupHCaptcha()
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
                authInstrument?.submitInteraction(action: "hcaptcha_success")
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
            guard let config = WMFDeveloperSettingsDataController.shared.loadFeatureConfig()?.ios.hCaptcha else {
                authInstrument?.submitInteraction(action: "hcaptcha_error", actionContext: ["error": CustomError.hCaptchaMissingConfig.logDescription])
                errorAction?(CustomError.hCaptchaMissingConfig)
                return
            }
            
            guard let baseURL = URL(string: config.baseURL),
                  let jsSrc = URL(string: config.jsSrc),
                  let endpoint = URL(string: config.endpoint),
                  let reportapi = URL(string: config.reportapi),
                  let assethost = URL(string: config.assethost),
                  let imghost = URL(string: config.imghost) else {
                    authInstrument?.submitInteraction(action: "hcaptcha_error", actionContext: ["error": CustomError.hCaptchaInvalidURL.logDescription])
                      errorAction?(CustomError.hCaptchaInvalidURL)
                      return
                  }
            
            hCaptcha = try HCaptcha(apiKey: config.apiKey,
                                     baseURL: baseURL,
                                     jsSrc: jsSrc,
                                     sentry: config.sentry,
                                     endpoint: endpoint,
                                     reportapi: reportapi,
                                     assethost: assethost,
                                     imghost: imghost,
                                     theme: theme.isDark ? "dark" : "light")
        } catch let error {
            authInstrument?.submitInteraction(action: "hcaptcha_error", actionContext: ["error": error.logDescription])
            errorAction?(error)
            return
        }
        
        let logError: (Any?) -> Void = { [weak self] data in
            if let error = data as? Error {
                self?.authInstrument?.submitInteraction(action: "hcaptcha_error", actionContext: ["error": error.logDescription])
            } else {
                self?.authInstrument?.submitInteraction(action: "hcaptcha_error")
            }
        }
        
        hCaptcha?.onEvent { [weak self] event, data in
            guard let self = self else { return }
            
            switch event {
            case .challengeExpired:
                logError(data)
                self.errorAction?(CustomError.hCaptchaExpired)
            case .close:
                logError(data)
                self.errorAction?(CustomError.hCaptchaClosed)
            case .error:
                logError(data)
                self.errorAction?(CustomError.hCaptchaError)
            case .expired:
                logError(data)
                self.errorAction?(CustomError.hCaptchaExpired)
            case .open:
                authInstrument?.submitInteraction(action: "hcaptcha_show")
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
        
        authInstrument?.submitInteraction(action: "hcaptcha_load")
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
