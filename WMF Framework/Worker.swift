@objc(WMFWorker) public protocol Worker: NSObjectProtocol {
    func doPeriodicWork(_ completion: @escaping () -> Void)
    func doBackgroundWork(_ completion: @escaping (UIBackgroundFetchResult) -> Void)
}
