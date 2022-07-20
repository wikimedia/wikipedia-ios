import Foundation

public extension TimeInterval {
    static var oneMinute: TimeInterval {
        return TimeInterval(60)
    }
    
    static var tenMinutes: TimeInterval {
        return oneMinute * 10
    }
    
    static var oneHour: TimeInterval {
        return TimeInterval(oneMinute * 60)
    }

    static var oneDay: TimeInterval {
        return TimeInterval(oneHour * 24)
    }
}
