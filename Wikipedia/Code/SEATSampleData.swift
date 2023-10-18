import Foundation

struct SEATTaskItem: Codable, Equatable {
    let articleURL: String
    let articleTitle: String
    let articleDescription: String?
    let articleSummary: String
    let imageURL: String

    var imageFilename: String {
        return (imageURL as NSString).lastPathComponent
    }
}

final class SEATSampleData {

    static let shared = SEATSampleData()

    // Populate with sample data
    var availableTasks: [SEATTaskItem] = [
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 1", articleDescription: "Description", articleSummary: "Sample Summary 1", imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ae/Michael_Jordan_in_2014.jpg"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 2", articleDescription: "Description", articleSummary: "Sample Summary 2", imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/08/PIA21499_-_Artist%27s_Concept_of_Psyche_Spacecraft_with_Five-Panel_Array.jpg"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 3", articleDescription: "Description", articleSummary: "Sample Summary 3", imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/71/1885Benz.jpg"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 4", articleDescription: "Description", articleSummary: "Sample Summary 4", imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/12/Tabby_cat_with_visible_nictitating_membrane.jpg"),
        SEATTaskItem(articleURL: "en.wiki/123", articleTitle: "Sample Item 5", articleDescription: "Description", articleSummary: "Sample Summary 5", imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Solar_system.jpg/440px-Solar_system.jpg")
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
