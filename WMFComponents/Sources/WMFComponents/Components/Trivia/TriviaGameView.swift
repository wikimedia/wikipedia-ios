import SwiftUI

public struct TriviaGameView: View {
    @ObservedObject public var viewModel: TriviaGameSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: TriviaGameSessionViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Text("Wikipedia Games")
                .font(.largeTitle)
                .foregroundColor(.primary)
                .padding(.top)
            
            Text("Which came first?")
                .multilineTextAlignment(.center)
                .font(.title)
                .foregroundColor(Color.black.opacity(0.6))
                .padding(.top)
            
            VStack(spacing: 32) {

                eventCard(
                    event: viewModel.gameData.firstEvent,
                    date: viewModel.gameData.firstEventDate,
                    imageURL: viewModel.gameData.firstEventImageURL,
                    isFirst: true
                )
                
                eventCard(
                    event: viewModel.gameData.secondEvent,
                    date: viewModel.gameData.secondEventDate,
                    imageURL: viewModel.gameData.secondEventImageURL,
                    isFirst: false
                )
                
                if viewModel.hasAnswered {
                    Button("Exit Game") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func eventCard(event: String, date: String, imageURL: URL?, isFirst: Bool) -> some View {
        Button(action: {
            if !viewModel.hasAnswered {
                viewModel.selectEvent(isFirst: isFirst)
            }
        }) {
            VStack(spacing: 16) {
                
                HStack(alignment: .top, spacing: 16) {
       
                    Text(event)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray4))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                }

                if viewModel.hasAnswered {
                    Text(date)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if viewModel.hasAnswered && isUserSelection(isFirst: isFirst) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isCorrectChoice(isFirst: isFirst) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isCorrectChoice(isFirst: isFirst) ? .green : .red)
                            .font(.title2)

                        Text(viewModel.isCorrectChoice(isFirst: isFirst) ? "Correct!" : "Incorrect!")
                            .foregroundColor(viewModel.isCorrectChoice(isFirst: isFirst) ? .green : .red)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(12)
        }
        .disabled(viewModel.hasAnswered)
    }
    
    private func isUserSelection(isFirst: Bool) -> Bool {
        return (isFirst && viewModel.selectedFirst) || (!isFirst && !viewModel.selectedFirst)
    }
}
