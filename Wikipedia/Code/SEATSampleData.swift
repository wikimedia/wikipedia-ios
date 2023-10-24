import Foundation
import WKData

struct SEATItemViewModel: Equatable, Hashable {
    
    let project: WKProject
    let articleTitle: String
    let articleWikitext: String
    let articleDescription: String?
    let articleSummary: String
    let imageWikitext: String
    let imageWikitextFilename: String
    let imageCommonsFilename: String
    let imageThumbnailURLs: [String : URL]
    let imageWikitextLocation: Int
    let commonsURL: URL
    let articleURL: URL
}

final class SEATSampleData {
    
    static var shared: SEATSampleData = SEATSampleData()

    // Populate with sample data
    var availableTasks: [SEATItemViewModel] = []

    // Visited tasks in this session
    var visitedTasks: [SEATItemViewModel] = []

    /// Give the user a task they haven't visited yet, if possible
    func nextTask() -> SEATItemViewModel {
        guard !(visitedTasks.count == availableTasks.count) else {
            visitedTasks = []
            return nextTask()
        }

        guard let task = availableTasks.shuffled().randomElement() else {
            fatalError()
        }

        guard !visitedTasks.contains(where: { $0.articleTitle == task.articleTitle }) else {
            return nextTask()
        }

        visitedTasks.append(task)
        return task
    }

}
