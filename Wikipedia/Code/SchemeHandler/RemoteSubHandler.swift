import Foundation

protocol RemoteSubHandler {
    func dataTaskForUrl(_ url: URL, callback: Session.Callback) -> URLSessionTask
}
