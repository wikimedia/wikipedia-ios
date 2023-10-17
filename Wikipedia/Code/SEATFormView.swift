import SwiftUI
import Components

struct SEATFormView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appEnvironment = WKAppEnvironment.current

    private var theme: WKTheme {
        appEnvironment.theme
    }

    @SwiftUI.State var altText: String = ""
    var taskItem: SEATTaskItem

    // MARK: - Public

    var body: some View {
        ScrollView {
            VStack {
                header
                Divider()
                    .foregroundColor(Color(theme.border))
                form
            }
        }
        .navigationTitle("Add alt text")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") {
                    dismiss()
                }
            }
        }
    }

    var header: some View {
        HStack(alignment: .top) {
            Rectangle()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            VStack(alignment: .leading) {
                Text("Image")
                    .foregroundStyle(Color(theme.secondaryText))
                Text("Filename.jpg")
                    .foregroundStyle(Color(theme.link))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    var form: some View {
        VStack(alignment: .leading) {
            Text("Alternative Text")
            TextField("Describe this image", text: $altText)
            Divider()
            Text("Text description")
            Text("Guidance")
        }
        .padding()
    }

}

#Preview {
    SEATFormView(taskItem: SEATSampleData.shared.availableTasks.randomElement()!)
}
