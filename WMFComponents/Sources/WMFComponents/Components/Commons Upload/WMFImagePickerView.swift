import SwiftUI

struct ImageUploadFlowView: View {
    @State private var selectedImage: UIImage?
    @State private var showPhotoOptions = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        VStack {
            if let image = selectedImage {
                MediaDetailsView(image: image)
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Select or take a photo to upload")
                        .font(.headline)
                        .padding(.top, 8)

                    Button("Choose or Take Photo") {
                        showPhotoOptions = true
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showPhotoOptions) {
            Button("Take Photo") {
                imagePickerSource = .camera
                showImagePicker = true
            }
            Button("Choose from Library") {
                imagePickerSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            WMFImagePicker(image: $selectedImage, sourceType: imagePickerSource)
        }
    }
}

struct MediaDetailsView: View {
    let image: UIImage
    // ... other states from before

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ...

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    .padding(.horizontal)

                // ... rest of the UI
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Upload") {
                    // Handle upload
                }
            }
        }
    }
}

