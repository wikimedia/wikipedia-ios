import SwiftUI

struct ApplePayContentView: View {
    @SwiftUI.State var input: String = ""
    var body: some View {
        VStack {
            Group {
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
            }
            
            TextField("Enter Text", text: $input, onEditingChanged: { isEditing in
                postEditingNotifications(isEditing: isEditing)
            })
            .textFieldStyle(.roundedBorder)
            .padding()
            
            Group {
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
            }
            
            Group {
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
            }
            
            Group {
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
                Text("Testing")
            }
        }
        .padding([.top, .bottom], 20)
    }
    
    func postEditingNotifications(isEditing: Bool) {
        if isEditing {
            NotificationCenter.default.post(name: .swiftUITextfieldDidBeginEditing, object: nil)
        } else {
            NotificationCenter.default.post(name: .swiftUITextfieldDidEndEditing, object: nil)
        }
    }
}

struct ApplePayContentView_Previews: PreviewProvider {
    static var previews: some View {
        ApplePayContentView()
    }
}
