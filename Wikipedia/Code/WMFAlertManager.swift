import UIKit
import MessageUI

extension NSError {
    
    public func alertMessage() -> String {
        if(self.wmf_isNetworkConnectionError()){
            return NSLocalizedString("alert-no-internet", value:"There's no internet connection", comment:"Message shown in an alert banner when there is no connection to the internet.")
        }else{
            return self.localizedDescription
        }
    }
    
    public func alertType() -> TSMessageNotificationType {
        if(self.wmf_isNetworkConnectionError()){
            return .warning
        }else{
            return .error
        }
    }

}


open class WMFAlertManager: NSObject, TSMessageViewProtocol, MFMailComposeViewControllerDelegate {
    
    open static let sharedInstance = WMFAlertManager()

    override init() {
        super.init()
        TSMessage.addCustomDesignFromFile(withName: "AlertDesign.json")
        TSMessage.shared().delegate = self
    }
    
    
    open func showInTheNewsAlert(_ message: String?, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        if (message ?? "").isEmpty {
            return
        }
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: NSLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section"),
                subtitle: message,
                image: UIImage(named:"trending-notification-icon"),
                type: .message,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)
        })
    }
    

    open func showAlert(_ message: String?, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
    
         if (message ?? "").isEmpty {
             return
         }
         self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .message,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)
        })
    }

    open func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .success,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)

        })
    }

    open func showWarningAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .warning,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)
        })
    }

    open func showErrorAlert(_ error: NSError, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: error.alertMessage(),
                subtitle: nil,
                image: nil,
                type: error.alertType(),
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)
        })
    }
    
    open func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotification(in: nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .error,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                at: .top,
                canBeDismissedByUser: true)
        })
    }

    func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping ()->()){
        
        if(dismissPreviousAlerts){
            TSMessage.dismissAllNotifications(completion: { () -> Void in
                alertBlock()
            })
        }else{
            alertBlock()
        }
    }
    
    open func dismissAlert() {
        
        TSMessage.dismissActiveNotification()
    }

    open func dismissAllAlerts() {
        
        TSMessage.dismissAllNotifications()
    }

    open func customize(_ messageView: TSMessageView!) {
        
        if(messageView.notificationType == .message){
         messageView.contentFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
            messageView.titleFont = UIFont.systemFont(ofSize: 12)
        }
    }
    
    open func showEmailFeedbackAlertViewWithError(_ error: NSError) {
       let message = NSLocalizedString("request-feedback-on-error", value:"The app has encountered a problem that our developers would like to know more about. Please tap here to send us an email with the error details.", comment:"Displayed to beta users when they encounter an error we'd like feedback on")
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
                self.showErrorAlertWithMessage(NSLocalizedString("no-email-account-alert", value:"Please setup an email account on your device and try again.", comment:"Displayed to the user when they try to send a feedback email, but they have never set up an account on their device"), sticky: false, dismissPreviousAlerts: false) {
                    
                }
            }
        }
    }
    
    open func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
