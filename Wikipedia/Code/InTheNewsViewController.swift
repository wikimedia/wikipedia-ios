import UIKit

@objc(WMFInTheNewsViewController)
class InTheNewsViewController: UIViewController {
    
    let story: WMFFeedNewsStory
    
    required init(story: WMFFeedNewsStory) {
        self.story = story
        super.init(nibName: "InTheNewsViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    
}
