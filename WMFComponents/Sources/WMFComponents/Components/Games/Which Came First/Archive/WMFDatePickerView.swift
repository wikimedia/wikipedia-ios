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
            ScrollView {
                VStack(spacing: 0) {

                    headerSection
                        .padding(.top, 32)

                    calendarCard
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }

            dismissButton

            // todo: replace with our toast?
            if let msg = viewModel.toastMessage {
                toastView(msg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .background(Color(.systemBackground))
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 52))
                .foregroundColor(.primary)

            Group {
                Text(viewModel.title + " ")
                    .font(.title2).bold()
                + Text("Archive")
                    .font(.title2).fontWeight(.regular)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 8)

            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
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

            Spacer(minLength: Layout.calendarPadding)
        }
        .background(Color(.secondarySystemBackground))
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
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 16) {
                Button {
                    viewModel.goToPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.canGoBack ? .primary : .secondary.opacity(0.4))
                }
                .disabled(!viewModel.canGoBack)

                Button {
                    viewModel.goToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.canGoForward ? .primary : .secondary.opacity(0.4))
                }
                .disabled(!viewModel.canGoForward)
            }
        }
    }

    // MARK: Weekday headers

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.localizedStrings.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
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
                    .font(.system(size: 16, weight: day.isToday ? .bold : .regular))
                    .foregroundColor(dayCellTextColor(day))
                    .frame(width: Layout.daySize, height: Layout.daySize)

                Circle()
                    .fill(day.playedScore != nil ? Color.accentColor : Color.clear)
                    .frame(width: Layout.dotSize, height: Layout.dotSize)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .opacity(day.isInCurrentMonth ? 1 : 0.3)
    }

    private func dayCellTextColor(_ day: WMFDatePickerDay) -> Color {
        day.isToday ? .accentColor : .primary
    }

    // MARK: Dismiss button

    private var dismissButton: some View {
        HStack {
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            Spacer()
        }
    }

    // MARK: Toast

    private func toastView(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground))
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
