import Foundation

extension Date {

	// TODO: Document nil Date
    func dateAtMidnight(calendar: Calendar = .current) -> Date? {
		let components = DateComponents(day: 1)
		let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: components, to: startOfDay)
	}

}
