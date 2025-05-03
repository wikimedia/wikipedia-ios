import SwiftUI

struct WWMFCommonsUploadView: View {
    @State private var caption: String = ""
    @State private var description: String = ""

   var viewModel: WMFCommonsUploadViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Media details")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)

                Image("polar_bear") // Replace with actual image file - TODO - conversion to JPEG
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .padding(.horizontal)

                HStack(spacing: 4) { // TODO - update to toggle per Figma
                    Image(systemName: "location.slash")
                    Text("Image location removed")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Caption", text: $caption)
                        .textFieldStyle(.roundedBorder)

                    Link("Learn how to write a useful caption", destination: URL(string: "https://commons.wikimedia.org/wiki/Commons:Captions")!)
                        .font(.footnote)
                        .foregroundColor(.blue)

                    Text("\(caption.count)/250")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 4) {
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                    Link("Learn how to write a useful description", destination: URL(string: "https://commons.wikimedia.org/wiki/Commons:Descriptions")!)
                        .font(.footnote)
                        .foregroundColor(.blue)

                    Text("\(description.count)/250")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Creative Commons CC0 Waiver")
                        .font(.subheadline)
                        .bold()
                    Text("Release all rights, anyone is free to use this work in any way")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Button("Change license") {
                        // TODO - Action
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Upload") {
                    // TODO - Handle upload
                }
            }
        }
    }
}
