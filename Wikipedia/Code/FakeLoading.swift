
import Foundation

protocol FakeLoading {
    var fakeProgressController: FakeProgressController { get }
}

extension TalkPageContainerViewController: FakeLoading {
    
}

extension TalkPageReplyListViewController: FakeLoading {
    
}
