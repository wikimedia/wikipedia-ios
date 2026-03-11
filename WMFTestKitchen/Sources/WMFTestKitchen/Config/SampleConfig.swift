import Foundation

public struct SampleConfig: Codable {
    public let rate: Double
    public let unit: String

    public static let unitPageview = "pageview"
    public static let unitSession = "session"
    public static let unitDevice = "device"

    public init(rate: Double = 1.0, unit: String = SampleConfig.unitSession) {
        self.rate = rate
        self.unit = unit
    }
}
