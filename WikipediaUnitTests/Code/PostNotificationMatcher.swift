import Nimble

public func postNotification<T>(
                _ name: String,
                object: T? = nil,
                fromCenter center: NotificationCenter = NotificationCenter.default) -> MatcherFunc<T> where T: Equatable, T: AnyObject {
    return MatcherFunc { actual, failureMessage in
        var postedNotification: Notification? = nil
        let token = center.addObserver(forName: name, object: object, queue: nil) { notification in
            postedNotification = notification
        }
        defer {
            center.removeObserver(token)
        }

        try actual.evaluate()

        failureMessage.postfixMessage = "observe a notification"

        let centerDesc = center === NotificationCenter.default ? "defaultCenter" : center.description

        failureMessage.postfixMessage += " from \(centerDesc)"
        failureMessage.postfixMessage += " with name \(name)"
        if object != nil {
            failureMessage.postfixMessage += " and object \(object)"
        }

        failureMessage.actualValue = "\(postedNotification?.description ?? "no notification")"

        guard let notification = postedNotification else {
            return false
        }

        if let postedObject = notification.object as? T,
               postedObject != object {
            return false
        }

        return notification.name == name
    }
}

extension NMBObjCMatcher {
    public class func postNotificationMatcher(
                        forName name: String,
                        object: NSObject?,
                        fromCenter center: NotificationCenter) -> NMBObjCMatcher {
       // must be able to match nil since expectAction blocks always return nil
       return NMBObjCMatcher(canMatchNil: true) { (actualExpression: Expression<NSObject>,
                                                   failureMessage: FailureMessage) -> Bool in
            return try! postNotification(name,
                                         object: object,
                                         fromCenter: center).matches(actualExpression, failureMessage: failureMessage)
        }
    }
}
