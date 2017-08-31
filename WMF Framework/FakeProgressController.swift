import UIKit

@objc(WMFFakeProgressController)
public class FakeProgressController: NSObject {
    let progressView: UIProgressView
    
    @objc public init(progressView: UIProgressView) {
        self.progressView = progressView
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    // MARK: - Progress
    
    @objc fileprivate func incrementProgress() {
        guard !isProgressHidden && progressView.progress <= 0.69 else {
            return
        }
        
        let rand = 0.15 + Float(arc4random_uniform(15))/100
        progressView.setProgress(progressView.progress + rand, animated: true)
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    @objc fileprivate func hideProgress() {
        UIView.animate(withDuration: 0.3, animations: { self.progressView.alpha = 0 } )
    }
    
    @objc fileprivate func showProgress() {
        progressView.alpha = 1
    }
    
    @objc public func start() {
        progressView.setProgress(0, animated: false)
        isProgressHidden = false
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    @objc public func stop() {
        isProgressHidden = true
    }
    
    @objc public func finish() {
        progressView.setProgress(1.0, animated: true)
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
