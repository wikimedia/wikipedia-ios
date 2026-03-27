import Foundation

public protocol EventSender {
    func sendEvents(_ events: [Event])
}
