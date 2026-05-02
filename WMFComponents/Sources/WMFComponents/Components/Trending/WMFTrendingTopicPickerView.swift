import SwiftUI
import WMFData

struct WMFTrendingTopicPickerView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTrendingViewModel

    private var groupedTopics: [(group: String, topics: [WMFTrendingTopic])] {
        let groups = ["Culture", "History & Society", "Science, Technology & Math", "Regions"]
        var result: [(group: String, topics: [WMFTrendingTopic])] = []
        for group in groups {
            let topics = WMFTrendingTopic.allCases.filter { $0.groupName == group }
            if !topics.isEmpty {
                result.append((group: group, topics: topics))
            }
        }
        return result
    }

    var body: some View {
        NavigationView {
            styledTopicList
        }
    }

    private var styledTopicList: some View {
        topicList
            .listStyle(.insetGrouped)
            .background(Color(uiColor: appEnvironment.theme.paperBackground))
            .navigationTitle(viewModel.localizedStrings.topicPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
    }

    private var topicList: some View {
        List {
            ForEach(groupedTopics, id: \.group) { section in
                topicSection(section)
            }
        }
    }

    private func topicSection(_ section: (group: String, topics: [WMFTrendingTopic])) -> some View {
        Section(header: sectionHeader(section.group)) {
            ForEach(section.topics, id: \.rawValue) { topic in
                topicRow(topic)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.subheadline)))
            .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
    }

    private func topicRow(_ topic: WMFTrendingTopic) -> some View {
        Button {
            viewModel.selectTopic(topic)
        } label: {
            HStack {
                Text(topic.displayName)
                    .font(Font(WMFFont.for(.body)))
                    .foregroundColor(Color(uiColor: appEnvironment.theme.text))
                Spacer()
                if viewModel.selectedTopics.contains(topic) {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(uiColor: appEnvironment.theme.link))
                }
            }
        }
    }

    private var doneButton: some View {
        Button(viewModel.localizedStrings.topicPickerDoneButton) {
            viewModel.applyTopicSelection()
        }
        .font(Font(WMFFont.for(.semiboldSubheadline)))
        .foregroundColor(Color(uiColor: appEnvironment.theme.link))
    }
}
