
import UIKit
import MessageUI

extension NSError {
    
    public func alertMessage() -> String {
        if(self.wmf_isNetworkConnectionError()){
            return localizedStringForKeyFallingBackOnEnglish("alert-no-internet")
        }else{
            return self.localizedDescription
        }
    }
    
    public func alertType() -> TSMessageNotificationType {
        if(self.wmf_isNetworkConnectionError()){
            return .Warning
        }else{
            return .Error
        }
    }

}


open class WMFAlertManager: NSObject, TSMessageViewProtocol, MFMailComposeViewControllerDelegate {
    
    open static let sharedInstance = WMFAlertManager()

    override init() {
        TSMessage.addCustomDesignFromFileWithName("AlertDesign.json")
        super.init()
    }
    
    open func showAlert(_ message: String, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: @escaping ()->()?) {
    
         if (message ?? "").isEmpty {
             return
         }
         self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotificationInViewController(nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .Message,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                atPosition: .Top,
                canBeDismissedByUser: true)
        })
    }

    open func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: @escaping ()->()?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotificationInViewController(nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .Success,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                atPosition: .Top,
                canBeDismissedByUser: true)

        })
    }

    open func showWarningAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: @escaping ()->()?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotificationInViewController(nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .Warning,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                atPosition: .Top,
                canBeDismissedByUser: true)
        })
    }

    open func showErrorAlert(_ error: NSError, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: @escaping ()->()?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotificationInViewController(nil,
                title: error.alertMessage(),
                subtitle: nil,
                image: nil,
                type: error.alertType(),
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                atPosition: .Top,
                canBeDismissedByUser: true)
        })
    }
    
    open func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: @escaping ()->()?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            TSMessage.showNotificationInViewController(nil,
                title: message,
                subtitle: nil,
                image: nil,
                type: .Error,
                duration: sticky ? -1 : 2,
                callback: tapCallBack,
                buttonTitle: nil,
                buttonCallback: {},
                atPosition: .Top,
                canBeDismissedByUser: true)
        })
    }

    func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping ()->()){
        
        if(dismissPreviousAlerts){
            TSMessage.dismissAllNotificationsWithCompletion({ () -> Void in
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

    open func customizeMessageView(_ messageView: TSMessageView!) {
        
        
    }
    
    open func showEmailFeedbackAlertViewWithError(_ error: NSError) {
        let message = localizedStringForKeyFallingBackOnEnglish("request-feedback-on-error")
        showErrorAlertWithMessage(message, sticky: true, dismissPreviousAlerts: true) {
            self.dismissAllAlerts()
            if MFMailComposeViewController.canSendMail() {
                guard let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                    return
                }
                let vc = MFMailComposeViewController()
                vc.setSubject("Bug:\(WikipediaAppUtils.versionedUserAgent())")
                vc.setToRecipients(["mobile-ios-wikipedia@wikimedia.org"])
                vc.mailComposeDelegate = self
                vc.setMessageBody("Domain:\t\(error.domain)\nCode:\t\(error.code)\nDescription:\t\(error.localizedDescription)\n\n\n\nVersion:\t\(WikipediaAppUtils.versionedUserAgent())", isHTML: false)
                rootVC.presentViewController(vc, animated: true, completion: nil)
            } else {
                self.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("no-email-account-alert"), sticky: false, dismissPreviousAlerts: false, tapCallBack: nil)
            }
        }
    }
    
    open func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
