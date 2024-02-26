import SwiftUI
import WKData

struct WKArticleSummaryView: View {
    
    let articleSummary: WKArticleSummary

    var body: some View {
        Text(articleSummary.displayTitle)
    }
}
