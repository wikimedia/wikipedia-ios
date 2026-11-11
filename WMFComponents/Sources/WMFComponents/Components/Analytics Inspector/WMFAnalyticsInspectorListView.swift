import SwiftUI
import WMFData

/// The recent analytics events, newest first, with a filter and the payload of each event on demand.
struct WMFAnalyticsInspectorListView: View {

    @ObservedObject var viewModel: WMFAnalyticsInspectorViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @State private var expandedEventIDs: Set<UUID> = []

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var strings: WMFAnalyticsInspectorViewModel.LocalizedStrings {
        viewModel.localizedStrings
    }

    var body: some View {
        let filteredEvents = viewModel.filteredEvents
        List {
            Section {
                TextField(strings.searchPlaceholder, text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker(strings.streamPicker, selection: $viewModel.streamFilter) {
                    Text(strings.allStreams).tag(String?.none)
                    ForEach(viewModel.availableStreams, id: \.self) { stream in
                        Text(stream).tag(String?.some(stream))
                    }
                }
                .tint(Color(theme.secondaryText))
            }
            .listRowBackground(rowBackground)

            Section {
                if filteredEvents.isEmpty {
                    Text(strings.emptyList)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(theme.secondaryText))
                }
                ForEach(filteredEvents) { event in
                    row(for: event)
                }
            } header: {
                Text(strings.header(count: filteredEvents.count))
                    .font(Font(WMFFont.for(.boldFootnote)))
                    .foregroundStyle(Color(theme.secondaryText))
            }
            .listRowBackground(rowBackground)

            Section {
                ShareLink(item: viewModel.sessionExportText()) {
                    Text(strings.share(count: viewModel.events.count))
                        .foregroundStyle(Color(theme.link))
                }
                .disabled(viewModel.events.isEmpty)
                Button {
                    viewModel.clear()
                    expandedEventIDs.removeAll()
                } label: {
                    Text(strings.clear)
                        .foregroundStyle(Color(theme.destructive))
                }
            }
            .listRowBackground(rowBackground)
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
        .foregroundStyle(Color(theme.text))
    }

    private var rowBackground: some View {
        Color(theme.paperBackground)
    }

    @ViewBuilder
    private func row(for event: WMFInspectedAnalyticsEvent) -> some View {
        let isExpanded = expandedEventIDs.contains(event.id)
        VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: WMFSpacing.small) {
                Circle()
                    .fill(event.outcome.isDropped ? Color(theme.destructive) : Color(theme.accent))
                    .frame(width: 8, height: 8)
                Text(viewModel.title(for: event))
                    .font(Font(WMFFont.for(.boldCallout)))
                    .lineLimit(isExpanded ? nil : 1)
                Spacer(minLength: WMFSpacing.small)
                Text(viewModel.timeText(for: event))
                    .font(Font(WMFFont.for(.caption1)).monospacedDigit())
                    .foregroundStyle(Color(theme.secondaryText))
            }
            Text(viewModel.subtitle(for: event))
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.secondaryText))
                .lineLimit(isExpanded ? nil : 1)
            if event.outcome.isDropped {
                Text(viewModel.outcomeText(for: event))
                    .font(Font(WMFFont.for(.boldCaption1)))
                    .foregroundStyle(Color(theme.destructive))
            }
            if isExpanded {
                Text(event.prettyPrintedPayload())
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                    .padding(.top, WMFSpacing.xSmall)
                Button {
                    viewModel.copyPayload(of: event)
                } label: {
                    Label(strings.copyPayload, systemImage: "doc.on.doc")
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundStyle(Color(theme.link))
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isExpanded {
                expandedEventIDs.remove(event.id)
            } else {
                expandedEventIDs.insert(event.id)
            }
        }
    }
}
