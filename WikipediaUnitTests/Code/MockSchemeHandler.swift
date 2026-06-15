import Foundation
import WebKit
@testable import Wikipedia

final class MockSchemeHandler: SchemeHandler {

    var accessed = false

    required init(scheme: String, session: Session) {
        super.init(scheme: scheme, session: session)
        let didReceiveDataCallback: ((WKURLSchemeTask, Data) -> Void)? = { [weak self] _, _ in
            self?.accessed = true
        }
        self.didReceiveDataCallback = didReceiveDataCallback
    }
}
