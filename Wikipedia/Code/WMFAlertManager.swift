import UIKit
import MessageUI

extension NSError {
    
    public func alertMessage() -> String {
        if(self.wmf_isNetworkConnectionError()){
            return CommonStrings.noInternetConnection
        }else{
            return self.localizedDescription
        }
    }
    
    public func alertType() -> RMessageType {
        if(self.wmf_isNetworkConnectionError()){
            return .warning
        }else{
            return .error
        }
    }

}


open class WMFAlertManager: NSObject, RMessageProtocol, MFMailComposeViewControllerDelegate, Themeable {
    
    @objc static let sharedInstance = WMFAlertManager()

    var theme = Theme.standard
    public func apply(theme: Theme) {
        self.theme = theme
    }

    override init() {
        super.init()
        RMessage.shared().delegate = self
    }
    
    
    @objc func showInTheNewsAlert(_ message: String?, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        if (message ?? "").isEmpty {
            return
        }
        showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            let title = CommonStrings.inTheNewsTitle
            RMessage.showNotification(in: nil, title: title, subtitle: message, iconImage: UIImage(named:"trending-notification-icon"), type: .normal, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
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
         showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .normal, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: canBeDismissedByUser)
        })
    }

    @objc func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .success, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)

        })
    }

    @objc func showWarningAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        
        showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .warning, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    func showErrorAlert(_ error: Error, sticky:Bool,dismissPreviousAlerts:Bool, viewController: UIViewController? = nil, tapCallBack: (() -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: viewController, title: (error as NSError).alertMessage(), subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }
    
    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: dismissPreviousAlerts, viewController:nil, tapCallBack: tapCallBack)
    }
    
    @objc func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)? = nil) {
        
        showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    @objc func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping ()->()){
        DispatchQueue.main.async {
            if dismissPreviousAlerts {
                self.dismissAllAlerts {
                    alertBlock()
                }
            } else {
                alertBlock()
            }
        }
    }
    
    @objc func dismissAlert() {
        RMessage.dismissActiveNotification()
    }

    @objc func dismissAllAlerts(_ completion: @escaping () -> Void = {}) {
        RMessage.dismissAllNotifications(completion: completion)
    }

    @objc public func customize(_ messageView: RMessageView!) {
        messageView.backgroundColor = theme.colors.popoverBackground
        messageView.closeIconColor = theme.colors.primaryText
        messageView.subtitleTextColor = theme.colors.secondaryText
        messageView.buttonTitleColor = theme.colors.link
        switch messageView.messageType {
        case .error:
            messageView.titleTextColor = theme.colors.error
        case .warning:
            messageView.titleTextColor = theme.colors.warning
        case .success:
            messageView.titleTextColor = theme.colors.accent
        default:
            messageView.titleTextColor = theme.colors.link
        }
    }
    
    @objc func showEmailFeedbackAlertViewWithError(_ error: NSError) {
       let message = WMFLocalizedString("request-feedback-on-error", value:"The app has encountered a problem that our developers would like to know more about. Please tap here to send us an email with the error details.", comment:"Displayed to beta users when they encounter an error we'd like feedback on")
        showErrorAlertWithMessage(message, sticky: true, dismissPreviousAlerts: true) {
            self.dismissAllAlerts()
            if MFMailComposeViewController.canSendMail() {
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                    return
                }
                let vc = MFMailComposeViewController()
                vc.setSubject("Bug:\(WikipediaAppUtils.versionedUserAgent())")
                vc.setToRecipients(["mobile-ios-wikipedia@wikimedia.org"])
                vc.mailComposeDelegate = self
                vc.setMessageBody("Domain:\t\(error.domain)\nCode:\t\(error.code)\nDescription:\t\(error.localizedDescription)\n\n\n\nVersion:\t\(WikipediaAppUtils.versionedUserAgent())", isHTML: false)
                rootVC.present(vc, animated: true, completion: nil)
            } else {
                self.showErrorAlertWithMessage(WMFLocalizedString("no-email-account-alert", value:"Please setup an email account on your device and try again.", comment:"Displayed to the user when they try to send a feedback email, but they have never set up an account on their device"), sticky: false, dismissPreviousAlerts: false) {
                    
                }
            }
        }
    }
    
    @objc public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
