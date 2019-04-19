
import UIKit

protocol TalkPageDiscussionNewDelegate: class {
    func addDiscussion(viewController: TalkPageDiscussionNewViewController)
}

class TalkPageDiscussionNewViewController: ViewController {
    
    weak var delegate: TalkPageDiscussionNewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func tappedPublish(_ sender: UIButton) {
        delegate?.addDiscussion(viewController: self)
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
