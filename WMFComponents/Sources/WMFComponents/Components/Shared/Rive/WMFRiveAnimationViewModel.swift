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
    /// Text runs to keep to a maximum number of lines. See `WMFRiveTextFit`.
    let textFits: [WMFRiveTextFit]

    private var text: [WMFRiveText: String]
    private var numbers: [WMFRiveNumber: Double]
    private var images: [WMFRiveImage: Data]
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private var fitTask: Task<Void, Never>?
    private let loader: @MainActor (WMFRiveAnimation) async throws -> Rive
    private let imageDecoder: @MainActor (Data) async throws -> RiveRuntime.Image

    init(
        animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        images: [WMFRiveImage: Data] = [:],
        readBool: WMFRiveBool? = nil,
        textFits: [WMFRiveTextFit] = [],
        loader: @escaping @MainActor (WMFRiveAnimation) async throws -> Rive = WMFRiveWorkerProvider.makeRive,
        imageDecoder: @escaping @MainActor (Data) async throws -> RiveRuntime.Image = WMFRiveWorkerProvider.decodeImage
    ) {
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.images = images
        self.readBool = readBool
        self.textFits = textFits
        self.loader = loader
        self.imageDecoder = imageDecoder
    }

    deinit {
        loadTask?.cancel()
        imageTask?.cancel()
        fitTask?.cancel()
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
            validatePathsInDebug()
            applyValues()
            // Fit the text before the animation shows, so a long value never shows at the wrong size.
            await applyTextFits()
            guard !Task.isCancelled else { return }
            self.loadState = .loaded
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
        fitTask?.cancel()
        fitTask = nil
        rive = nil
        readBoolValue = nil
        loadState = .idle
    }

    func update(text newText: [WMFRiveText: String], numbers newNumbers: [WMFRiveNumber: Double]) {
        guard newText != text || newNumbers != numbers else { return }
        text = newText
        numbers = newNumbers
        applyValues()
        guard !textFits.isEmpty else { return }
        fitTask?.cancel()
        fitTask = Task { [weak self] in
            await self?.applyTextFits()
        }
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

    /// Binds a new instance of each global view model that a fit uses, also when the value fits, so a
    /// shorter value returns to the size in the file.
    private func applyTextFits() async {
        guard let rive, !textFits.isEmpty else { return }

        struct Measured {
            let fit: WMFRiveTextFit
            let global: ViewModelInstance
            let fontSize: Double
            let lineHeight: Double
            let scale: Double
        }

        var globals: [String: ViewModelInstance] = [:]
        var measured: [Measured] = []
        for fit in textFits {
            guard let value = text[fit.text], !value.isEmpty else { continue }
            do {
                let global: ViewModelInstance
                if let existing = globals[fit.globalViewModelName] {
                    global = existing
                } else {
                    global = try await rive.file.createViewModelInstance(.viewModelDefault(from: .name(fit.globalViewModelName)))
                    globals[fit.globalViewModelName] = global
                }
                let fontSize = Double(try await global.value(of: NumberProperty(path: fit.fontSize.path)))
                let lineHeight = Double(try await global.value(of: NumberProperty(path: fit.lineHeight.path)))
                guard let scale = fit.scale(for: value, fontSize: fontSize) else {
                    WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "No system font for the asset \"\(fit.fontAssetName)\", so \"\(fit.text.path)\" is not fitted."))
                    continue
                }
                measured.append(Measured(fit: fit, global: global, fontSize: fontSize, lineHeight: lineHeight, scale: scale))
            } catch {
                WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "Could not fit \"\(fit.text.path)\": \(error.localizedDescription)"))
            }
        }

        // The runs of a group use the smallest scale of the group.
        var groupScales: [String: Double] = [:]
        for item in measured {
            guard let group = item.fit.group else { continue }
            groupScales[group] = min(groupScales[group] ?? 1, item.scale)
        }
        for item in measured {
            let scale = item.fit.group.flatMap { groupScales[$0] } ?? item.scale
            item.global.setValue(of: NumberProperty(path: item.fit.fontSize.path), to: Float(item.fontSize * scale))
            item.global.setValue(of: NumberProperty(path: item.fit.lineHeight.path), to: Float(item.lineHeight * scale))
        }

        guard !Task.isCancelled else { return }
        for (name, global) in globals {
            do {
                try await rive.stateMachine.bindViewModelInstances { (name, global) }
            } catch {
                WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "Could not bind the global view model \"\(name)\": \(error.localizedDescription)"))
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
