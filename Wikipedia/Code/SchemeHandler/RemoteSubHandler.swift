import Foundation

protocol RemoteSubHandler {
    func dataTaskForRequest(_ request: URLRequest, callback: Session.Callback) -> URLSessionTask
}
