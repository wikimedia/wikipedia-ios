import WMFTestKitchen
import CocoaLumberjackSwift

class TestKitchenLogAdapter: LogAdapter {
    func info(_ message: String) {
        DDLogInfo("TestKitchen: \(message)")
    }

    func warn(_ message: String) {
        DDLogWarn("TestKitchen: \(message)")
    }

    func error(_ message: String) {
        DDLogError("TestKitchen: \(message)")
    }
}
