import Foundation

struct SEATTaskItem: Codable, Equatable {
    let articleURL: String
    let articleTitle: String
    let articleDescription: String?
    let articleSummary: String
    let imageURL: String
}

final class SEATSampleData {

    static let shared = SEATSampleData()

    // Populate with sample data
    var availableTasks: [SEATTaskItem] = [
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 1", articleDescription: "Description", articleSummary: "Sample Summary 1", imageURL: "imageurl"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 2", articleDescription: "Description", articleSummary: "Sample Summary 2", imageURL: "imageurl"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 3", articleDescription: "Description", articleSummary: "Sample Summary 3", imageURL: "imageurl"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 4", articleDescription: "Description", articleSummary: "Sample Summary 4", imageURL: "imageurl"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 5", articleDescription: "Description", articleSummary: "Sample Summary 5", imageURL: "imageurl")
    ]

    // Visited tasks in this session
    var visitedTasks: [SEATTaskItem] = []

    /// Give the user a task they haven't visited yet, if possible
    func nextTask() -> SEATTaskItem {
        guard !(visitedTasks.count == availableTasks.count) else {
            visitedTasks = []
            return nextTask()
        }

        guard let task = availableTasks.shuffled().randomElement() else {
            fatalError()
        }

        guard !visitedTasks.contains(where: { $0 == task }) else {
            return nextTask()
        }

        visitedTasks.append(task)
        return task
    }

}
