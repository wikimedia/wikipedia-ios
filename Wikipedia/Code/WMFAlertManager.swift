import WMFComponents
import MessageUI

extension NSError {
    
    public func alertType() -> RMessageType {
        if self.wmf_isNetworkConnectionError() {
            return .warning
        } else {
            return .error
        }
    }

}

open class WMFAlertManager: NSObject, RMessageProtocol, Themeable {
    
    @objc static let sharedInstance = WMFAlertManager()

    var theme = Theme.standard
    public func apply(theme: Theme) {
        self.theme = theme
    }

    override init() {
        super.init()
        RMessage.shared().delegate = self
    }

    @objc func showAlertWithReadMore(_ title: String?, type: RMessageType, dismissPreviousAlerts: Bool, buttonCallback: (() -> Void)?, tapCallBack: (() -> Void)?) {
        showAlert(dismissPreviousAlerts) {
            RMessage.showNotification(in: nil, title: title, subtitle: nil, iconImage: nil, type: type, customTypeName: nil, duration: -1, callback: tapCallBack, buttonTitle: "Read more", buttonCallback: buttonCallback, at: .top, canBeDismissedByUser: true)
        }
    }

    @objc func showAlert(_ message: String?, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (() -> Void)? = nil) {
        showAlert(message, sticky: sticky, canBeDismissedByUser: true, dismissPreviousAlerts: dismissPreviousAlerts, tapCallBack: tapCallBack)
    }
    
    
    public func showAlert(_ message: String?, sticky: Bool, canBeDismissedByUser: Bool, dismissPreviousAlerts: Bool, tapCallBack: (() -> Void)?) {
    
         if (message ?? "").isEmpty {
             return
         }
         showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .normal, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: canBeDismissedByUser)
        })
    }

    @objc func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .success, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)

        })
    }

    @objc func showWarningAlert(_ message: String, duration: NSNumber? = nil, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        
        let finalDuration = duration?.intValue ?? 2
        
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .warning, customTypeName: nil, duration: sticky ? -1 : TimeInterval(finalDuration), callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    func showErrorAlert(_ error: Error, sticky:Bool, dismissPreviousAlerts:Bool, viewController: UIViewController? = nil, tapCallBack: (() -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: viewController, title: (error as NSError).alertMessage(), subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }
    
    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: dismissPreviousAlerts, viewController:nil, tapCallBack: tapCallBack)
    }
    
    @objc func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    @objc func showErrorAlertWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(in: nil, title: message, subtitle: subtitle, iconImage: image, type: .custom, customTypeName: "connection", duration: 15, callback: tapCallBack, buttonTitle: buttonTitle, buttonCallback: tapCallBack, at: .top, canBeDismissedByUser: true)
        })
    }
    
    func showBottomAlertWithMessage(_ message: String, subtitle: String?, image: UIImage?, type: RMessageType, customTypeName: String?, duration: TimeInterval? = nil, dismissPreviousAlerts:Bool, callback: (() -> Void)? = nil, buttonTitle: String? = nil, buttonCallBack: (() -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            RMessage.showNotification(withTitle: message, subtitle: subtitle, iconImage: image, type: type, customTypeName: customTypeName, duration: duration ?? 5, callback: callback, buttonTitle: buttonTitle, buttonCallback: buttonCallBack, at: .bottom, canBeDismissedByUser: true)
        })
    }
    
    private var queuedAlertBlocks: [() -> Void] = []

    @objc func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping () -> Void) {
        DispatchQueue.main.async {
            if dismissPreviousAlerts {
                self.queuedAlertBlocks.append(alertBlock)
                self.dismissAllAlerts {
                    assert(Thread.isMainThread)
                    if let alertBlock = self.queuedAlertBlocks.popLast() {
                        alertBlock()
                    }
                    self.queuedAlertBlocks.removeAll()
                }
            } else {
                alertBlock()
            }
        }
    }
    
    func topMessageView() -> RMessageView {
        return RMessage.currentMessageView()
    }
    
    @objc func dismissAlert() {
        RMessage.dismissActiveNotification()
    }

    @objc func dismissAllAlerts(_ completion: @escaping () -> Void = {}) {
        RMessage.dismissAllNotifications(completion: completion)
    }

    @objc public func customize(_ messageView: RMessageView!) {
        messageView.backgroundColor = theme.colors.chromeBackground
        messageView.closeIconColor = theme.colors.primaryText
        messageView.subtitleTextColor = theme.colors.secondaryText
        messageView.buttonTitleColor = theme.colors.link
        messageView.imageViewTintColor = theme.colors.link
        switch messageView.messageType {
        case .error:
            messageView.titleTextColor = theme.colors.error
        case .warning:
            messageView.titleTextColor = theme.colors.warning
        case .success:
            messageView.titleTextColor = theme.colors.accent
        case .custom:
            messageView.titleTextColor = theme.colors.primaryText
            messageView.subtitleTextColor = theme.colors.primaryText
            if messageView.customTypeName == "connection" {
                messageView.imageViewTintColor = theme.colors.error
                messageView.buttonFont = WMFFont.for(.boldSubheadline)
            } else if messageView.customTypeName == "subscription-error" {
                messageView.imageViewTintColor = theme.colors.warning
            } else if messageView.customTypeName == "watchlist-add-remove-success" {
                messageView.buttonFont = WMFFont.for(.boldSubheadline)
            } else if messageView.customTypeName == "donate-success" {
                messageView.imageViewTintColor = theme.colors.error
            } else if messageView.customTypeName == "edit-preview-simplified-format" {
                // no additional customization needed
            } else if messageView.customTypeName == "edit-published" {
                messageView.titleTextColor = theme.colors.primaryText
            } else if messageView.customTypeName == "feedback-submitted" {
                messageView.titleTextColor = theme.colors.primaryText
            }
        default:
            messageView.titleTextColor = theme.colors.link
        }
        
        messageView.layer.shadowColor = theme.colors.shadow.cgColor
    }

}
