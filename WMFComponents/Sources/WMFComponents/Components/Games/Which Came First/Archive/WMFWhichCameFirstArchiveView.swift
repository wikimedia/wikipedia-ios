import SwiftUI

private enum Layout {
    static let daySize: CGFloat = 36
    static let dotSize: CGFloat = 11
    static let cornerRadius: CGFloat = 16
    static let calendarPadding: CGFloat = 12
    static let emptyCellSpacing: CGFloat = 4
}

public struct WMFWhichCameFirstArchiveView: View {

    @ObservedObject public var viewModel: WMFWhichCameFirstArchiveViewModel

    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    var onDismiss: (() -> Void)?

    public init(viewModel: WMFWhichCameFirstArchiveViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 100)
                        .padding(.bottom, 32)

                    calendarCard
                        .shadow(color: Color(uiColor: theme.text).opacity(0.05), radius: 8, x: 0, y: 0)
                        .padding(.horizontal, 16)

                    Spacer()
                }
            }

            dismissButton
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(Color(uiColor: theme.text))
                .frame(width: 98, height: 72)
                .padding(.bottom, 12)

            Group {
                Text(viewModel.localizedStrings.title + " ")
                    .font(Font(WMFFont.for(.boldTitle1)))
                + Text(viewModel.localizedStrings.archiveLabel)
                    .font(Font(WMFFont.for(.title1)))
            }
            .foregroundColor(Color(uiColor: theme.text))
            .multilineTextAlignment(.center)

            Text(viewModel.localizedStrings.subtitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundColor(Color(uiColor: theme.text))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        CalendarRepresentable(viewModel: viewModel, theme: theme)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: theme.paperBackground))
            .cornerRadius(Layout.cornerRadius)
            .dynamicTypeSize(.small ... .medium)
    }

    // MARK: Dismiss button

    private var dismissButton: some View {
        HStack {
            Button {
                onDismiss?()
            } label: {
                if let xmark = WMFSFSymbolIcon.for(symbol: .xMark, font: .footnote) {
                    Image(uiImage: xmark)
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
            }
            .modifier(GlassCircleEffect())
            .padding(.leading, 16)
            .padding(.top, 16)
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
        // Background is intentionally .clear — the SwiftUI layer provides the card background.
        uiView.tintColor = theme.link
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
            if viewModel.playedDates[normalised] != nil || viewModel.pausedDates.contains(normalised) {
                return .default(color: calendarView.tintColor)
            }
            return nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            self.selection?.setSelected(nil, animated: false)
            viewModel.selectDay(date)
        }
    }
}
