import UIKit

/// Simulated archive entry for a given date.
private struct ArchiveEntry {
    let title: String
    let summary: String
}

/// Proof-of-concept view controller showing a UICalendarView where
/// dates with archive entries are decorated with a dot, and tapping
/// one reveals the archive content below.
final class DatePickerTestViewController: UIViewController {

    // MARK: - Simulated archive data

    /// Build a dictionary keyed by (year, month, day) tuples from today backwards.
    private let archiveData: [Date: ArchiveEntry] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: today)!
        }
        return [
            daysAgo(2):  ArchiveEntry(title: "Apollo 11 Landing",
                                      summary: "NASA astronauts landed on the Moon for the first time."),
            daysAgo(5):  ArchiveEntry(title: "Internet Invented",
                                      summary: "Tim Berners-Lee proposed the World Wide Web."),
            daysAgo(9):  ArchiveEntry(title: "Wikipedia Founded",
                                      summary: "Wikipedia was launched as a free online encyclopedia."),
            daysAgo(14): ArchiveEntry(title: "First iPhone Released",
                                      summary: "Apple introduced the original iPhone, changing mobile computing."),
            daysAgo(21): ArchiveEntry(title: "Linux Kernel Announced",
                                      summary: "Linus Torvalds announced a new free operating system kernel."),
            daysAgo(30): ArchiveEntry(title: "Hubble Space Telescope",
                                      summary: "The Hubble Space Telescope was launched into orbit."),
            daysAgo(45): ArchiveEntry(title: "DNA Double Helix",
                                      summary: "Watson and Crick published the structure of DNA.")
        ]
    }()

    // MARK: - Views

    private let calendarView = UICalendarView()
    private lazy var selectionBehavior = UICalendarSelectionSingleDate(delegate: self)

    private let archiveCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let archiveTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .headline)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let archiveSummaryLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let noArchiveLabel: UILabel = {
        let l = UILabel()
        l.text = "No archive entry for this date."
        l.font = UIFont.preferredFont(forTextStyle: .body)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Picker test"
        view.backgroundColor = .systemBackground
        setupCalendarView()
        setupArchiveCard()
        setupNoArchiveLabel()
    }

    // MARK: - Setup

    private func setupCalendarView() {
        calendarView.selectionBehavior = selectionBehavior
        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        view.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupArchiveCard() {
        archiveCardView.addSubview(archiveTitleLabel)
        archiveCardView.addSubview(archiveSummaryLabel)
        view.addSubview(archiveCardView)

        NSLayoutConstraint.activate([
            archiveCardView.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 20),
            archiveCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            archiveCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            archiveTitleLabel.topAnchor.constraint(equalTo: archiveCardView.topAnchor, constant: 14),
            archiveTitleLabel.leadingAnchor.constraint(equalTo: archiveCardView.leadingAnchor, constant: 14),
            archiveTitleLabel.trailingAnchor.constraint(equalTo: archiveCardView.trailingAnchor, constant: -14),

            archiveSummaryLabel.topAnchor.constraint(equalTo: archiveTitleLabel.bottomAnchor, constant: 6),
            archiveSummaryLabel.leadingAnchor.constraint(equalTo: archiveCardView.leadingAnchor, constant: 14),
            archiveSummaryLabel.trailingAnchor.constraint(equalTo: archiveCardView.trailingAnchor, constant: -14),
            archiveSummaryLabel.bottomAnchor.constraint(equalTo: archiveCardView.bottomAnchor, constant: -14)
        ])
    }

    private func setupNoArchiveLabel() {
        view.addSubview(noArchiveLabel)
        NSLayoutConstraint.activate([
            noArchiveLabel.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 20),
            noArchiveLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            noArchiveLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Helpers

    /// Returns the archive entry for a given DateComponents, if one exists.
    private func archiveEntry(for dateComponents: DateComponents) -> ArchiveEntry? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let dayStart = Calendar.current.startOfDay(for: date)
        return archiveData[dayStart]
    }

    /// Normalises a Date to midnight so it matches the archiveData keys.
    private func archiveEntry(for date: Date) -> ArchiveEntry? {
        let dayStart = Calendar.current.startOfDay(for: date)
        return archiveData[dayStart]
    }
}

// MARK: - UICalendarViewDelegate (decorations)

extension DatePickerTestViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard archiveEntry(for: dateComponents) != nil else { return nil }
        // Show a small orange dot beneath dates that have an archive entry.
        return .default(color: .systemOrange, size: .small)
    }
}

// MARK: - UICalendarSelectionSingleDateDelegate

extension DatePickerTestViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents else {
            archiveCardView.isHidden = true
            noArchiveLabel.isHidden = true
            return
        }

        if let entry = archiveEntry(for: dateComponents) {
            archiveTitleLabel.text = entry.title
            archiveSummaryLabel.text = entry.summary
            archiveCardView.isHidden = false
            noArchiveLabel.isHidden = true
        } else {
            archiveCardView.isHidden = true
            noArchiveLabel.isHidden = false
        }
    }
}
