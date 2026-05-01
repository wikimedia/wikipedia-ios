import SwiftUI
import WMFData

struct WMFTrendingTopicPickerView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFTrendingViewModel

    private var groupedTopics: [(group: String, topics: [WMFTrendingTopic])] {
        let groups = ["Culture", "History & Society", "Science, Technology & Math", "Regions"]
        return groups.compactMap { group in
            let topics = WMFTrendingTopic.allCases.filter { $0.groupName == group }
            return topics.isEmpty ? nil : (group: group, topics: topics)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTopics, id: \.group) { section in
                    Section(header: Text(section.group)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                    ) {
                        ForEach(section.topics, id: \.rawValue) { topic in
                            Button {
                                viewModel.selectTopic(topic)
                            } label: {
                                HStack {
                                    Text(topic.displayName)
                                        .font(Font(WMFFont.for(.body)))
                                        .foregroundColor(Color(uiColor: appEnvironment.theme.text))
                                    Spacer()
                                    if viewModel.selectedTopic == topic {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(uiColor: appEnvironment.theme.link))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(uiColor: appEnvironment.theme.paperBackground))
            .navigationTitle(viewModel.localizedStrings.topicPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingTopicPicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(uiColor: appEnvironment.theme.text))
                    }
                }
            }
        }
    }
}
