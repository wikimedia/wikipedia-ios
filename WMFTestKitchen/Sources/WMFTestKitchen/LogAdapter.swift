import Foundation

public protocol LogAdapter {
    func info(_ message: String)
    func warn(_ message: String)
    func error(_ message: String)
}
