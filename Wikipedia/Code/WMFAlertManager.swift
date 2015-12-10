
import UIKit
import TSMessages


extension NSError {
    
    public func alertMessage() -> String {
        if(self.wmf_isNetworkConnectionError()){
            return "The network is unreachable"
        }else{
            return self.localizedDescription
        }
    }
}


public class WMFAlertManager: NSObject, TSMessageViewProtocol {
    
    public static let sharedInstance = WMFAlertManager()

    override init() {
        TSMessage.addCustomDesignFromFileWithName("AlertDesign.json")
        super.init()
    }
   
    public func showAlert(message: String, sticky:Bool, tapCallBack: dispatch_block_t?) {
        
        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(),
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
        
    }

    public func showSuccessAlert(message: String, sticky:Bool, tapCallBack: dispatch_block_t?) {
        
        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(),
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
        
    }

    public func showWarningAlert(message: String, sticky:Bool, tapCallBack: dispatch_block_t?) {
        
        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(),
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
        
    }

    public func showErrorAlert(error: NSError, sticky:Bool, tapCallBack: dispatch_block_t?) {
        
        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(),
            title: error.alertMessage(),
            subtitle: nil,
            image: nil,
            type: .Error,
            duration: sticky ? -1 : 2,
            callback: tapCallBack,
            buttonTitle: nil,
            buttonCallback: {},
            atPosition: .Top,
            canBeDismissedByUser: true)
        
    }
    
    public func hideAlert() {
        
        TSMessage.dismissActiveNotification()
    }
    
    public func customizeMessageView(messageView: TSMessageView!) {
        
        
    }
}
