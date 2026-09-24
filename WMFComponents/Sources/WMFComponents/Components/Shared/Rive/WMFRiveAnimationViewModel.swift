import Foundation
import RiveRuntime

@MainActor
final class WMFRiveAnimationViewModel: ObservableObject {

    enum LoadState {
        case idle
        case loading
        case loaded
        case failed

        var isLoaded: Bool {
            if case .loaded = self { return true }
            return false
        }
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var rive: Rive?

    let animation: WMFRiveAnimation

    private var text: [WMFRiveText: String]
    private var numbers: [WMFRiveNumber: Double]
    private var loadTask: Task<Void, Never>?
    private let loader: @MainActor (WMFRiveAnimation) async throws -> Rive

    init(
        animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        loader: @escaping @MainActor (WMFRiveAnimation) async throws -> Rive = WMFRiveWorkerProvider.makeRive
    ) {
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.loader = loader
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        guard loadTask == nil, !loadState.isLoaded else { return }
        loadTask = Task { [weak self] in
            await self?.load()
        }
    }

    func load() async {
        loadState = .loading
        do {
            let rive = try await loader(animation)
            guard !Task.isCancelled else { return }
            self.rive = rive
            self.loadState = .loaded
            validatePathsInDebug()
            applyValues()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.rive = nil
            self.loadState = .failed
            self.loadTask = nil
            WMFRiveLogger.log(
                WMFRiveFailure(animation: animation, stage: stage(for: error), reason: error.localizedDescription)
            )
        }
    }

    func unload() {
        loadTask?.cancel()
        loadTask = nil
        rive = nil
        loadState = .idle
    }

    func update(text newText: [WMFRiveText: String], numbers newNumbers: [WMFRiveNumber: Double]) {
        guard newText != text || newNumbers != numbers else { return }
        text = newText
        numbers = newNumbers
        applyValues()
    }

    private func applyValues() {
        guard let instance = rive?.viewModelInstance else { return }
        for (property, value) in text {
            instance.setValue(of: StringProperty(path: property.path), to: value)
        }
        for (property, value) in numbers {
            instance.setValue(of: NumberProperty(path: property.path), to: Float(value))
        }
    }

    private func stage(for error: any Error) -> WMFRiveFailure.Stage {
        if error is WorkerError || error is WMFRiveError {
            return .worker
        }
        return .file
    }

    private func validatePathsInDebug() {
        #if DEBUG
        guard let rive, !text.isEmpty || !numbers.isEmpty else { return }
        let stringPaths = text.keys.map(\.path)
        let numberPaths = numbers.keys.map(\.path)
        Task { [animation] in
            guard let instance = rive.viewModelInstance else { return }

            for path in stringPaths where (try? await instance.value(of: StringProperty(path: path))) == nil {
                report(path: path, type: "string", animation: animation)
            }

            for path in numberPaths where (try? await instance.value(of: NumberProperty(path: path))) == nil {
                report(path: path, type: "number", animation: animation)
            }
        }
        #endif
    }

    #if DEBUG
    private func report(path: String, type: String, animation: WMFRiveAnimation) {
        let failure = WMFRiveFailure(
            animation: animation,
            stage: .binding,
            reason: "No \(type) data binding property at path \"\(path)\"."
        )
        WMFRiveLogger.log(failure)
        assertionFailure(failure.reason)
    }
    #endif
}
