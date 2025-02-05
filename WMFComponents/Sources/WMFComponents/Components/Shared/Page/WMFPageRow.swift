import SwiftUI


/// A reusable component for displaying a page row (typically an article) with swipe actions. These should be embedded inside of a List.
struct WMFPageRow: View {
    
    let id: String
    let titleHtml: String
    let description: String?
    let imageURL: URL?
    let deleteItemAction: (String) -> Void
    
    var body: some View {
        Text(titleHtml)
            .swipeActions {
                Button("Delete") {
                    deleteItemAction(id)
                }
                .tint(.green)
            }
    }
}
