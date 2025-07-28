import SwiftUI

struct TriviaGameView: View {
    @ObservedObject var viewModel: TriviaGameSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Wikipedia Games")
                .font(.largeTitle)
                .padding(.top)

            Spacer()

            switch viewModel.gameState {
            case .loading:
                ProgressView("Loading question...")
            case .question:
                VStack(spacing: 16) {
                    Text(viewModel.questionText)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    ForEach(viewModel.answerOptions, id: \.self) { option in
                        Button(action: {
                            viewModel.selectAnswer(option)
                        }) {
                            Text(option)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            case .answered(let isCorrect):
                VStack(spacing: 16) {
                    Text(viewModel.questionText)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    ForEach(viewModel.answerOptions, id: \.self) { option in
                        let isSelected = (option == viewModel.selectedAnswer)
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isSelected ? (isCorrect ? Color.green : Color.red) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text(isCorrect ? "Correct!" : "Wrong!")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.headline)
                    
                    Button("Exit Game") {
                        dismiss()
                    }
                    .padding(.top)
                }
            }

            Spacer()
        }
        .padding()
    }
}
