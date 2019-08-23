
import Foundation

protocol FakeProgressLoading {
    var fakeProgressController: FakeProgressController { get }
}

extension TalkPageContainerViewController: FakeProgressLoading {
    
}

extension TalkPageReplyListViewController: FakeProgressLoading {
    
}
