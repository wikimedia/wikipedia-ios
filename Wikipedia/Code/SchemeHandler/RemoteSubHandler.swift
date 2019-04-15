import Foundation

protocol RemoteSubHandler {
    func dataTaskForURL(_ url: URL, callback: Session.Callback) -> URLSessionTask
}
