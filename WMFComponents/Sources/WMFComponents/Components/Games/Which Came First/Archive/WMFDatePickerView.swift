import SwiftUI

// MARK: - Constants

public enum Layout {
    static let daySize: CGFloat = 40
    static let dotSize: CGFloat = 7
    static let cornerRadius: CGFloat = 16
    static let toastCornerRadius: CGFloat = 12
    static let calendarPadding: CGFloat = 16
}

// MARK: - WMFDatePickerView

public struct WMFDatePickerView: View {

    @StateObject public var viewModel: WMFDatePickerViewModel

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    var onDismiss: (() -> Void)?

    public init(
        viewModel: WMFDatePickerViewModel,
        onDismiss: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()

            GeometryReader { proxy in
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .padding(.top, 56)

                    calendarCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .frame(height: proxy.size.height, alignment: .center)
            }

            dismissButton

            if let msg = viewModel.toastMessage {
                toastView(msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 52))
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.bottom, 4)

            Group {
                Text(viewModel.title + " ")
                    .font(Font(WMFFont.for(.boldTitle3)))
                + Text(viewModel.localizedStrings.archiveLabel)
                    .font(Font(WMFFont.for(.title3)))
            }
            .foregroundColor(Color(uiColor: theme.text))
            .multilineTextAlignment(.center)
            .padding(.top, 4)

            Text(viewModel.subtitle)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        VStack(spacing: 0) {
            monthNavigationBar
                .padding(.horizontal, Layout.calendarPadding)
                .padding(.top, Layout.calendarPadding)
                .padding(.bottom, 8)

            weekdayHeaders
                .padding(.horizontal, Layout.calendarPadding)

            Divider()
                .padding(.vertical, 6)
                .padding(.horizontal, Layout.calendarPadding)

            ForEach(Array(viewModel.weeks.enumerated()), id: \.offset) { _, week in
                weekRow(week)
                    .padding(.horizontal, Layout.calendarPadding)
            }
        }
        .padding(.bottom, Layout.calendarPadding)
        .background(Color(uiColor: theme.paperBackground))
        .cornerRadius(Layout.cornerRadius)
    }

    // MARK: Month navigation

    private var monthNavigationBar: some View {
        HStack {
            Button {
                // Year picker navigation hook (future)
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.displayedMonthTitle)
                        .font(Font(WMFFont.for(.headline)))
                        .foregroundColor(Color(uiColor: theme.text))
                    Image(systemName: "chevron.right")
                        .font(Font(WMFFont.for(.caption1)).weight(.bold))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.localizedStrings.monthPickerA11y)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    viewModel.goToPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.canGoBack
                            ? Color(uiColor: theme.text)
                            : Color(uiColor: theme.secondaryText).opacity(0.4))
                }
                .disabled(!viewModel.canGoBack)
                .accessibilityLabel(viewModel.localizedStrings.previousMonthA11y)

                Button {
                    viewModel.goToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.canGoForward
                            ? Color(uiColor: theme.text)
                            : Color(uiColor: theme.secondaryText).opacity(0.4))
                }
                .disabled(!viewModel.canGoForward)
                .accessibilityLabel(viewModel.localizedStrings.nextMonthA11y)
            }
        }
    }

    // MARK: Weekday headers

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(Font(WMFFont.for(.caption2)).weight(.semibold))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Week row

    private func weekRow(_ week: [WMFDatePickerDay?]) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { col in
                if let day = week[safe: col] ?? nil {
                    dayCell(day)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.daySize + Layout.dotSize + 4)
                }
            }
        }
    }

    // MARK: Day cell

    private func dayCell(_ day: WMFDatePickerDay) -> some View {
        Button {
            viewModel.selectDay(day)
        } label: {
            VStack(spacing: 2) {
                Text("\(day.dayNumber)")
                    .font(Font(WMFFont.for(day.isToday ? .boldCallout : .callout)))
                    .foregroundColor(dayCellTextColor(day))
                    .frame(width: Layout.daySize, height: Layout.daySize)

                Circle()
                    .fill(dayCellDotColor(day))
                    .frame(width: Layout.dotSize, height: Layout.dotSize)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .opacity(day.isInCurrentMonth ? 1 : 0.3)
        .accessibilityLabel(dayCellAccessibilityLabel(day))
    }

    private func dayCellTextColor(_ day: WMFDatePickerDay) -> Color {
        day.isToday ? Color(uiColor: theme.link) : Color(uiColor: theme.text)
    }

    private func dayCellDotColor(_ day: WMFDatePickerDay) -> Color {
        if day.playedScore != nil || day.isPaused {
            return Color(uiColor: theme.link)
        }
        return .clear
    }

    private func dayCellAccessibilityLabel(_ day: WMFDatePickerDay) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        var parts = [formatter.string(from: day.date)]
        if let score = day.playedScore {
            parts.append(String.localizedStringWithFormat(viewModel.localizedStrings.dayScoreA11yFormat, score))
        } else if day.isPaused {
            parts.append(viewModel.localizedStrings.dayPausedA11y)
        }
        return parts.joined(separator: ", ")
    }

    // MARK: Dismiss button

    private var dismissButton: some View {
        HStack {
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(Font(WMFFont.for(.footnote)).weight(.semibold))
                    .foregroundColor(Color(uiColor: theme.text))
                    .padding(10)
                    .background {
                        if #available(iOS 26.0, *) {
                            Color.clear
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .clipShape(Circle())
            }
            .modifier(GlassCircleEffect())
            .padding(.leading, 16)
            .padding(.top, 16)
            .accessibilityLabel(viewModel.localizedStrings.dismissA11y)
            Spacer()
        }
    }
    
    private struct GlassCircleEffect: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content.glassEffect(in: Circle())
            } else {
                content
            }
        }
    }
    
    // MARK: Toast

    private func toastView(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(Font(WMFFont.for(.subheadline)).weight(.semibold))
                .foregroundColor(Color(uiColor: theme.text))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(uiColor: theme.paperBackground))
                .cornerRadius(Layout.toastCornerRadius)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }
}

// MARK: - Safe subscript helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview helpers

private extension Date {
    static func today(offsetBy days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Calendar.current.startOfDay(for: Date()))!
    }
}

// MARK: - Previews

#Preview("Default – current month, some played days") {
    WMFDatePickerView(
        viewModel: WMFDatePickerViewModel(
            localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
            playedDates: [
                .today(offsetBy: -2): 5,
                .today(offsetBy: -5): 3,
                .today(offsetBy: -9): 4,
                .today(offsetBy: -14): 2
            ],
            onSelectDate: { date in print("Selected: \(date)") }
        ),
        onDismiss: {}
    )
}

#Preview("With paused dates") {
    WMFDatePickerView(
        viewModel: WMFDatePickerViewModel(
            localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
            playedDates: [
                .today(offsetBy: -2): 5,
                .today(offsetBy: -5): 3
            ],
            pausedDates: [
                .today(offsetBy: -1),
                .today(offsetBy: -7)
            ],
            onSelectDate: { date in print("Selected: \(date)") }
        ),
        onDismiss: {}
    )
}

#Preview("Empty – no played days") {
    WMFDatePickerView(
        viewModel: WMFDatePickerViewModel(
            localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
            playedDates: [:]
        ),
        onDismiss: {}
    )
}

#Preview("Archive start month (June 2024)") {
    let archiveStart = DateComponents(calendar: .current, year: 2024, month: 6, day: 1).date!
    let vm = WMFDatePickerViewModel(
        localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
        archiveStartDate: archiveStart,
        playedDates: [
            DateComponents(calendar: .current, year: 2024, month: 6, day: 5).date!: 5,
            DateComponents(calendar: .current, year: 2024, month: 6, day: 12).date!: 1
        ]
    )
    return WMFDatePickerView(viewModel: vm, onDismiss: {})
}

#Preview("Weekday symbol override (French)") {
    WMFDatePickerView(
        viewModel: WMFDatePickerViewModel(
            localizedStrings: WMFDatePickerViewModel.LocalizedStrings(
                title: "Lequel est venu en premier?",
                subtitle: "Jouez depuis juin 2024.",
                weekdaySymbolOverrides: ["DIM", "LUN", "MAR", "MER", "JEU", "VEN", "SAM"]
            ),
            playedDates: [.today(offsetBy: -3): 4]
        ),
        onDismiss: {}
    )
}

#Preview("Dark mode") {
    WMFDatePickerView(
        viewModel: WMFDatePickerViewModel(
            localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
            playedDates: [
                .today(offsetBy: -1): 4,
                .today(offsetBy: -3): 5
            ]
        ),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Presented as sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WMFDatePickerView(
                viewModel: WMFDatePickerViewModel(
                    localizedStrings: WMFDatePickerViewModel.LocalizedStrings(),
                    playedDates: [
                        .today(offsetBy: -4): 3,
                        .today(offsetBy: -7): 5
                    ]
                ),
                onDismiss: {}
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
}
