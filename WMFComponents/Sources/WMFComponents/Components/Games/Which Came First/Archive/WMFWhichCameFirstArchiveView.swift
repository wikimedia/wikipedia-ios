import SwiftUI

public struct WMFWhichCameFirstArchiveView: View {

    @ObservedObject public var viewModel: WMFWhichCameFirstArchiveViewModel

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFWhichCameFirstArchiveViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 32)

                    calendarCard
                        .shadow(color: Color(uiColor: theme.text).opacity(0.05), radius: 8, x: 0, y: 0)
                        .padding(.horizontal, 16)

                    Spacer()
                }
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            if let icon = WMFSFSymbolIcon.for(symbol: .calendarBadgeClock)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 64)) {
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .foregroundColor(Color(uiColor: theme.text))
                    .frame(width: 98, height: 72)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
            }

            Group {
                Text(viewModel.title + " ")
                    .font(Font(WMFFont.for(.boldTitle2)))
                + Text(viewModel.archiveLabel)
                    .font(Font(WMFFont.for(.title2)))
            }
            .foregroundColor(Color(uiColor: theme.text))
            .multilineTextAlignment(.center)

            Text(viewModel.subtitle)
                .font(Font(WMFFont.for(.body)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        CalendarRepresentable(viewModel: viewModel, theme: theme)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: theme.paperBackground))
            .cornerRadius(16)
            .dynamicTypeSize(.small ... .medium)
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
        // Force the calendar's text/background palette to match the WMF theme to avoid issues when app theme is not a match to device theme
        cv.overrideUserInterfaceStyle = theme.userInterfaceStyle
        // Background is transparent — the SwiftUI layer provides the card background.
        cv.backgroundColor = .clear

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        cv.selectionBehavior = selection
        context.coordinator.selection = selection

        cv.availableDateRange = DateInterval(
            start: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: viewModel.archiveStartDate)) ?? viewModel.archiveStartDate,
            end: Date()
        )

        return cv
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        uiView.tintColor = theme.link
        uiView.overrideUserInterfaceStyle = theme.userInterfaceStyle
        uiView.reloadDecorations(forDateComponents: viewModel.decoratedDateComponents, animated: false)
    }

    @MainActor
    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {

        let viewModel: WMFWhichCameFirstArchiveViewModel
        weak var selection: UICalendarSelectionSingleDate?

        init(viewModel: WMFWhichCameFirstArchiveViewModel) {
            self.viewModel = viewModel
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let normalised = Calendar.current.startOfDay(for: date)
            guard viewModel.playedDates[normalised] != nil else {
                return nil
            }
            let image = UIImage(systemName: "circlebadge.fill")?.withRenderingMode(.alwaysTemplate) // not adding our component to avoid formatting issues.
            image?.accessibilityLabel = viewModel.decorationAccessibilityLabel(for: date)
            return .image(image, color: calendarView.tintColor)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            self.selection?.setSelected(nil, animated: false)
            viewModel.selectDay(date)
        }
    }
}
