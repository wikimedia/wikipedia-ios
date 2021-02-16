@objc class BasicLogger: NSObject, DDLogger {
    func log(message logMessage: DDLogMessage) {
        print(logFormatter?.format(message: logMessage) ?? logMessage.message)
    }

    var logFormatter: DDLogFormatter?
}
