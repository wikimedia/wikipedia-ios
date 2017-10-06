
class WMFWelcomeScrollViewVerticalScrollIndicatorFlashingViewController: UIViewController {
    @IBOutlet fileprivate var scrollViewToFlash:UIScrollView!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollViewToFlash.showsVerticalScrollIndicator = true
        scrollViewToFlash.showsHorizontalScrollIndicator = false
        dispatchOnMainQueueAfterDelayInSeconds(1.5) {
            let canScroll = self.scrollViewToFlash.contentSize.height - self.scrollViewToFlash.bounds.size.height > 0
            // Only flash indicator if there is hidden content which can be scrolled to.
            if canScroll {
                self.scrollViewToFlash.flashScrollIndicators()
            }
        }
    }
}
