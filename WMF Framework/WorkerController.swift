import Foundation

@objc(WMFWorkerControllerDelegate) public protocol WorkerControllerDelegate: NSObjectProtocol {
    func workerControllerWillStart(_ periodicWorkerController: WorkerController, workWithIdentifier: String)
    func workerControllerDidEnd(_ periodicWorkerController: WorkerController,  workWithIdentifier: String)
}

@objc(WMFWorkerController) public class WorkerController: NSObject {
    @objc public weak var delegate: WorkerControllerDelegate?
    
    @objc public func cancelWorkWithIdentifier(_ identifier: String) {
        // subclassers should override
    }
}
