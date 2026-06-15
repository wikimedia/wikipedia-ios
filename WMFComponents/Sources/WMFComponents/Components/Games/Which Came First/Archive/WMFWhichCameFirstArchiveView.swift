import SwiftUI

// MARK: - Constants

private enum Layout {
    static let dotSize: CGFloat = 6
    static let calendarPadding: CGFloat = 16
}

// MARK: - WMFWhichCameFirstArchiveView

public struct WMFWhichCameFirstArchiveView: View {

    @ObservedObject public var viewModel: WMFWhichCameFirstArchiveViewModel

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    public init(viewModel: WMFWhichCameFirstArchiveViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.paperBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    subtitleView
                        .padding(.horizontal, Layout.calendarPadding)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    CalendarRepresentable(viewModel: viewModel, theme: theme)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Layout.calendarPadding)
                }
            }
        }
    }

    private var subtitleView: some View {
        Text(viewModel.localizedStrings.subtitle)
            .font(Font(WMFFont.for(.headline)))
            .foregroundColor(Color(uiColor: theme.secondaryText))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - UICalendarView bridge

private struct CalendarRepresentable: UIViewRepresentable {

    let viewModel: WMFWhichCameFirstArchiveViewModel
    let theme: WMFTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let cv = UICalendarView()
        cv.delegate = context.coordinator
        cv.tintColor = theme.link
        cv.backgroundColor = .clear

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        cv.selectionBehavior = selection
        context.coordinator.selection = selection

        let startComponents = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.archiveStartDate)
        let endComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        cv.availableDateRange = DateInterval(
            start: Calendar.current.date(from: startComponents) ?? viewModel.archiveStartDate,
            end: Calendar.current.date(from: endComponents) ?? Date()
        )

        return cv
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        uiView.tintColor = theme.link
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {

        let viewModel: WMFWhichCameFirstArchiveViewModel
        weak var selection: UICalendarSelectionSingleDate?

        init(viewModel: WMFWhichCameFirstArchiveViewModel) {
            self.viewModel = viewModel
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let normalised = Calendar.current.startOfDay(for: date)
            if viewModel.playedDates[normalised] != nil || viewModel.pausedDates.contains(normalised) {
                return .default(color: calendarView.tintColor)
            }
            return nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            self.selection?.setSelected(nil, animated: false)
            Task { @MainActor in
                self.viewModel.selectDay(date)
            }
        }
    }
}
