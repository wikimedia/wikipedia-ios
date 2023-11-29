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
    let imageDetailsURL: URL
    let articleURL: URL
    
    var displayImageThumbnailURL: URL? {
        return imageThumbnailURLs["2"] ?? imageThumbnailURLs["1.5"] ?? imageThumbnailURLs["1"]
    }
}

final class SEATSampleData {

    enum SurveyURL: String {
        case en = "https://docs.google.com/forms/d/e/1FAIpQLSdIQnhq9bg8Gq_rBTC6bi4hvpUv1nIaImroO68QOT5YKDCVRA/viewform?usp=sf_link"
        case es = "https://docs.google.com/forms/d/e/1FAIpQLSekmtei3NfD2EH1zpamoPPCqvbakvZCFdr4Vq3AKMxnyarSMw/viewform?usp=sf_link"
        case pt = "https://docs.google.com/forms/d/e/1FAIpQLSdydhZYnRpDFnoqg437bP9OfvTuk9nx8T0VZ7BHnuYiac9yPQ/viewform?usp=sf_link"
    }

    enum PrivacyURL: String {
        case en = "https://foundation.wikimedia.org/wiki/Legal:Feedback_Survey_for_the_%22Add_alt_text%22_feature_in_%22Suggested_Edits%22_Privacy_Statement"
        case es = "https://foundation.wikimedia.org/wiki/Legal:Feedback_Survey_for_the_%22Add_alt_text%22_feature_in_%22Suggested_Edits%22_Privacy_Statement/es"
        case pt = "https://foundation.wikimedia.org/wiki/Legal:Feedback_Survey_for_the_%22Add_alt_text%22_feature_in_%22Suggested_Edits%22_Privacy_Statement/pt-br"
    }

    static var shared: SEATSampleData = SEATSampleData()

    var surveyURL: SurveyURL!
    var privacyURL: PrivacyURL!

    var hasPresentedFeedbackOnSubmitThisSession = false

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
