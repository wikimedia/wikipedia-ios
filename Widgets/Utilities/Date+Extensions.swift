import Foundation

extension Date {

    /// Return a randomized `Date` in the next midnight hour. Will return nil if a `Date` can't be constructed given the calendar
    /// and component constraints, though in practice will likely always return some value.
    func randomDateShortlyAfterMidnight(calendar: Calendar = .current) -> Date? {
        let components = DateComponents(day: 1, minute: .random(in: 0..<30), second: .random(in: 0..<60))
        let startOfDay = calendar.startOfDay(for: self)
        return calendar.date(byAdding: components, to: startOfDay)
    }

}
