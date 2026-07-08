import SwiftUI

// MARK: - Image Quiz Slide

struct WMFYiR2026ImageQuizSlideView: View {

    let data: WMFYiR2026ImageQuizSlideData
    let selectedOptionIndex: Int?
    let onSelect: (Int) -> Void

    @State private var contentVisible = false
    @State private var pressedIndex: Int? = nil

    private let gap: CGFloat = 10
    private let sidePad: CGFloat = 16
    private var tileSize: CGFloat {
        (UIScreen.main.bounds.width - sidePad * 2 - gap) / 2
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [data.accentColor, data.accentColor.opacity(0.5), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let lottieName = data.lottieName {
                WMFLottieView(animationName: lottieName, loopMode: .loop)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 24) {
                Text(data.question)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: gap) {
                    HStack(spacing: gap) {
                        tile(index: 0)
                        tile(index: 1)
                    }
                    HStack(spacing: gap) {
                        tile(index: 2)
                        tile(index: 3)
                    }
                }
                .padding(.horizontal, sidePad)
                .frame(height: tileSize * 2 + gap)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(contentVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentVisible)
        .onAppear { contentVisible = true }
        .onDisappear { contentVisible = false }
    }

    // MARK: Tile
    // Uses a Group so @ViewBuilder always returns one consistent type

    @ViewBuilder
    private func tile(index: Int) -> some View {
        Group {
            if index < data.options.count {
                let option = data.options[index]
                tileButton(option: option, index: index)
            } else {
                Color.clear
            }
        }
        .frame(width: tileSize, height: tileSize)
    }

    @ViewBuilder
    private func tileButton(option: WMFYiR2026ImageOption, index: Int) -> some View {
        let isSelected = selectedOptionIndex == index
        let answered = selectedOptionIndex != nil
        let isCorrect = option.isCorrect
        let isWrong = isSelected && !isCorrect

        let borderColor: Color = {
            guard answered else { return .white.opacity(0.25) }
            if isCorrect { return .green }
            if isWrong { return .red }
            return .white.opacity(0.1)
        }()

        Button {
            guard selectedOptionIndex == nil else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                onSelect(index)
            }
        } label: {
            ZStack {
                if let urlString = option.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ProgressView().tint(.white)
                        default:
                            Color.white.opacity(0.1)
                        }
                    }
                } else {
                    Color.white.opacity(0.1)
                }

                if answered {
                    Group {
                        if isCorrect { Color(red: 0.18, green: 0.65, blue: 0.35).opacity(0.65) } else if isWrong { Color(red: 0.80, green: 0.20, blue: 0.20).opacity(0.65) } else { Color.black.opacity(0.5) }
                    }
                }

                if answered && (isSelected || isCorrect) {
                    Image(systemName: isWrong ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: tileSize, height: tileSize)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: answered && (isCorrect || isWrong) ? 3 : 1)
            )
            .opacity(!answered || isSelected || isCorrect ? 1.0 : 0.45)
            .scaleEffect(pressedIndex == index ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressedIndex = index }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.15)) { pressedIndex = nil } }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: answered)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WMFYiR2026ImageQuizSlideView(
        data: .init(
            accentColor: Color(red: 0.05, green: 0.45, blue: 0.40),
            question: "Which of these appeared in your most-visited article?",
            options: [
                .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/99/Welsh_Pembroke_Corgi.jpg",         isCorrect: false),
                .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0e/Dolina-dolnej-wisly-2.jpg",        isCorrect: true),
                .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/34/Pommes_d_amour.jpg",              isCorrect: false),
                .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/f2/Shipwreck_of_the_SS_American_Star_on_the_shore_of_Fuerteventura.jpg", isCorrect: false)
            ]
        ),
        selectedOptionIndex: nil,
        onSelect: { _ in }
    )
}
#endif
