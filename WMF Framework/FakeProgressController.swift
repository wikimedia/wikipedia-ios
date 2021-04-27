import UIKit

public protocol FakeProgressReceiving {
    var progress: Float { get }
    func setProgress(_ progress: Float, animated: Bool)
}

public protocol FakeProgressDelegate: AnyObject {
    func setProgressHidden(_ hidden: Bool, animated: Bool)
}

public class FakeProgressController: NSObject {
    private let progress: FakeProgressReceiving
    weak var delegate: FakeProgressDelegate?
    public var minVisibleDuration: TimeInterval = 0.7
    public var delay: TimeInterval = 1.0
    
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
    
    fileprivate var isProgressHidden: Bool = true
    
    @objc private func hideProgress() {
        isProgressHidden = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(incrementProgress), object: nil)
        self.delegate?.setProgressHidden(true, animated: true)
    }
    
    @objc private func showProgress() {
        isProgressHidden = false
        self.delegate?.setProgressHidden(false, animated: false)
    }
    
    private func cancelPreviousShowsAndHides() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showProgress), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideProgress), object: nil)
    }
    
    public func start() {
        assert(Thread.isMainThread)
        cancelPreviousShowsAndHides()
        perform(#selector(showProgress), with: nil, afterDelay: delay)
        progress.setProgress(0, animated: false)
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    public func stop() {
        assert(Thread.isMainThread)
        cancelPreviousShowsAndHides()
        perform(#selector(hideProgress), with: nil, afterDelay: minVisibleDuration)
    }
    
    public func finish() {
        progress.setProgress(1.0, animated: true)
        stop()
    }
    
}
