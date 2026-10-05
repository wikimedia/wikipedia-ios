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
    /// The value of `readBool` in the loaded file. `nil` until the file loads, or if the file has no such property.
    @Published private(set) var readBoolValue: Bool?

    let animation: WMFRiveAnimation
    /// A boolean property to read after the file loads, from the view model instance that has the name
    /// of the artboard if there is one, otherwise from the bound instance.
    let readBool: WMFRiveBool?

    private var text: [WMFRiveText: String]
    private var numbers: [WMFRiveNumber: Double]
    private var images: [WMFRiveImage: Data]
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private let loader: @MainActor (WMFRiveAnimation) async throws -> Rive
    private let imageDecoder: @MainActor (Data) async throws -> RiveRuntime.Image

    init(
        animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        images: [WMFRiveImage: Data] = [:],
        readBool: WMFRiveBool? = nil,
        loader: @escaping @MainActor (WMFRiveAnimation) async throws -> Rive = WMFRiveWorkerProvider.makeRive,
        imageDecoder: @escaping @MainActor (Data) async throws -> RiveRuntime.Image = WMFRiveWorkerProvider.decodeImage
    ) {
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.images = images
        self.readBool = readBool
        self.loader = loader
        self.imageDecoder = imageDecoder
    }

    deinit {
        loadTask?.cancel()
        imageTask?.cancel()
    }

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard loadTask == nil, !loadState.isLoaded else { return nil }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.load()
        }
        loadTask = task
        return task
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
            await readBoolFromFile()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.rive = nil
            self.loadTask = nil
            self.loadState = .failed
            WMFRiveLogger.log(
                WMFRiveFailure(animation: animation, stage: stage(for: error), reason: error.localizedDescription)
            )
        }
    }

    func unload() {
        loadTask?.cancel()
        loadTask = nil
        imageTask?.cancel()
        imageTask = nil
        rive = nil
        readBoolValue = nil
        loadState = .idle
    }

    func update(text newText: [WMFRiveText: String], numbers newNumbers: [WMFRiveNumber: Double]) {
        guard newText != text || newNumbers != numbers else { return }
        text = newText
        numbers = newNumbers
        applyValues()
    }

    func update(images newImages: [WMFRiveImage: Data]) {
        guard newImages != images else { return }
        images = newImages
        applyImages()
    }

    private func applyValues() {
        guard let instance = rive?.viewModelInstance else { return }
        for (property, value) in text {
            instance.setValue(of: StringProperty(path: property.path), to: value)
        }
        for (property, value) in numbers {
            instance.setValue(of: NumberProperty(path: property.path), to: Float(value))
        }
        applyImages()
    }

    /// Decoding is async, so the images arrive after the text. An image that does not decode keeps
    /// the placeholder inside the .riv.
    private func applyImages() {
        imageTask?.cancel()
        guard let instance = rive?.viewModelInstance, !images.isEmpty else { return }
        let images = images
        imageTask = Task { [weak self] in
            for (property, data) in images {
                guard let self else { return }
                do {
                    let image = try await self.imageDecoder(data)
                    guard !Task.isCancelled else { return }
                    instance.setValue(of: ImageProperty(path: property.path), to: image)
                } catch {
                    guard !Task.isCancelled else { return }
                    WMFRiveLogger.log(WMFRiveFailure(animation: self.animation, stage: .binding, reason: "Could not decode the image for \"\(property.path)\": \(error.localizedDescription)"))
                }
            }
        }
    }

    /// `dataBind: .auto` binds the default instance of the artboard. The templates set their flags on
    /// the instance that has the name of the artboard, so read that instance first.
    private func readBoolFromFile() async {
        guard let readBool, let rive else { return }
        let property = BoolProperty(path: readBool.path)
        var value: Bool?
        if let artboardName = animation.artboardName,
           let named = try? await rive.file.createViewModelInstance(.name(artboardName, from: .artboardDefault(rive.artboard))) {
            value = try? await named.value(of: property)
        }
        if value == nil, let bound = rive.viewModelInstance {
            value = try? await bound.value(of: property)
        }
        guard !Task.isCancelled else { return }
        readBoolValue = value
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
