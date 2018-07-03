import UIKit

public protocol FakeProgressReceiving {
    var progress: Float { get }
    func setProgress(_ progress: Float, animated: Bool)
}

public protocol FakeProgressDelegate: class {
    func setProgressHidden(_ hidden: Bool, animated: Bool)
}

public class FakeProgressController: NSObject {
    private let progress: FakeProgressReceiving
    weak var delegate: FakeProgressDelegate?
    
    public init(progress: FakeProgressReceiving, delegate: FakeProgressDelegate?) {
        self.progress = progress
        self.delegate = delegate
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // MARK: - Progress
    
    @objc private func incrementProgress() {
        guard !isProgressHidden && progress.progress <= 0.69 else {
            return
        }
        
        let rand = 0.15 + Float(arc4random_uniform(15))/100
        progress.setProgress(progress.progress + rand, animated: true)
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    @objc private func hideProgress() {
        self.delegate?.setProgressHidden(true, animated: true)
    }
    
    @objc private func showProgress() {
        self.delegate?.setProgressHidden(false, animated: false)
    }
    
    public func start() {
        progress.setProgress(0, animated: false)
        isProgressHidden = false
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    public func stop() {
        isProgressHidden = true
    }
    
    public func finish() {
        progress.setProgress(1.0, animated: true)
        isProgressHidden = true
    }
    
    fileprivate var isProgressHidden: Bool = false {
        didSet{
            if isProgressHidden {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showProgress), object: nil)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(incrementProgress), object: nil)
                perform(#selector(hideProgress), with: nil, afterDelay: 0.7)
            } else {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideProgress), object: nil)
                showProgress()
            }
        }
    }
}
