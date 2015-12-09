
import UIKit
import TSMessages

@objc public enum WMFAlertType: Int {
    
    case Error
    case StaticError
    case ArticleLanguageDownload
    case NoSearchResults
    case TestError
    case TestWarning
    case TestSuccess
    case TestMessage
    
}

public class WMFAlert: NSObject {

    public let type: WMFAlertType
    public var error: NSError?

    init(error: NSError){
        self.error = error
        self.type = .Error
        super.init()
    }

    init(staticError: NSError){
        self.error = staticError
        self.type = .StaticError
        super.init()
    }

    init(type: WMFAlertType){
        self.type = type
        super.init()
    }
    
    public var messageTitle: String {
        switch self.type {
        case .Error:
            if let error = self.error {
                if(self.error!.wmf_isNetworkConnectionError()){
                    return "The network is unreachable"
                }else{
                    return error.localizedDescription
                }
            }else{
                return "Error"
            }
        case .StaticError:
            if let error = self.error {
                if(self.error!.wmf_isNetworkConnectionError()){
                    return "The network is unreachable"
                }else{
                    return error.localizedDescription
                }
            }else{
                return "Error"
            }
        case .ArticleLanguageDownload:
            return localizedStringForKeyFallingBackOnEnglish("article-languages-downloading")
        case .NoSearchResults:
            return localizedStringForKeyFallingBackOnEnglish("search-no-matches")
        case .TestError:
            return "There was an error"
        case .TestWarning:
            return "You have been warned"
        case .TestSuccess:
            return "You are successful"
        case .TestMessage:
            return "You have been notified"
        }
    }

    public var messageSubtitle: String? {
        return nil
    }
    
    public var messageType: TSMessageNotificationType {
        switch self.type {
        case .Error:
            return .Error
        case .TestError:
            return .Error
        case .TestWarning:
            return .Warning
        case .TestSuccess:
            return .Success
        default:
            return .Message
        }
    }
    
    public var messageDuration: NSTimeInterval {
        switch self.type {
        case .ArticleLanguageDownload:
            return -1
        case .StaticError:
            return -1
        default:
            return 2
        }
    }

    public var messageUserDismissable: Bool {
        return true
    }

    public var messageButtonDismisses: Bool {
        return true
    }

}

public class WMFAlertManager: NSObject, TSMessageViewProtocol {
    
    public static let sharedInstance = WMFAlertManager()

    override init() {
        TSMessage.addCustomDesignFromFileWithName("AlertDesign.json")
        super.init()
    }
    
    public func showAlert(alert: WMFAlert, tapCallBack: dispatch_block_t?) {
        
        TSMessage.showNotificationInViewController(TSMessage.defaultViewController(),
            title: alert.messageTitle,
            subtitle: alert.messageSubtitle,
            image: nil,
            type: alert.messageType,
            duration: alert.messageDuration,
            callback: tapCallBack,
            buttonTitle: nil,
            buttonCallback: alert.messageButtonDismisses ? {} : nil,
            atPosition: .Top,
            canBeDismissedByUser: alert.messageUserDismissable)
        
    }
    
    public func customizeMessageView(messageView: TSMessageView!) {
        
        
    }
}
