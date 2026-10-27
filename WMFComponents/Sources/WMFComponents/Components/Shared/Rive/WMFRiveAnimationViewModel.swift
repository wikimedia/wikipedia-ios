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
    /// Goes up by one each time the loaded file fires `watchedTrigger`, or sets `watchedBool` from false to true.
    @Published private(set) var watchedEventCount = 0

    let animation: WMFRiveAnimation
    /// A boolean property to read after the file loads, from the view model instance that has the name
    /// of the artboard if there is one, otherwise from the bound instance.
    let readBool: WMFRiveBool?
    let watchedTrigger: WMFRiveTrigger?
    let watchedBool: WMFRiveBool?
    /// Text runs to keep to a maximum number of lines. See `WMFRiveTextFit`.
    let textFits: [WMFRiveTextFit]

    /// The font size and the line height of a fit in the .riv, before the fit changes them.
    struct FileSizes {
        let fontSize: Double
        let lineHeight: Double
    }

    /// The instances that the state machine binds when it is made, and the values they got.
    struct Bound {
        let main: ViewModelInstance?
        let globals: [String: ViewModelInstance]
        let fileSizes: [WMFRiveTextFit: FileSizes]
        let text: [WMFRiveText: String]
        let numbers: [WMFRiveNumber: Double]
        let bools: [WMFRiveBool: Bool]
        let enums: [WMFRiveEnum: String]

        var bindings: WMFRiveBindings {
            WMFRiveBindings(main: main, globals: globals)
        }
    }

    /// The view model instance that the state machine binds. `nil` until the file loads.
    var boundInstance: ViewModelInstance? {
        bound?.main
    }

    private var text: [WMFRiveText: String]
    private var numbers: [WMFRiveNumber: Double]
    private var bools: [WMFRiveBool: Bool]
    private var enums: [WMFRiveEnum: String] = [:]
    private var images: [WMFRiveImage: Data]
    private var bound: Bound?
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private var triggerTask: Task<Void, Never>?
    private var boolTask: Task<Void, Never>?
    private let loader: @MainActor (WMFRiveAnimation, WMFRiveBindingsMaker) async throws -> Rive
    private let imageDecoder: @MainActor (Data) async throws -> RiveRuntime.Image

    init(
        animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        bools: [WMFRiveBool: Bool] = [:],
        images: [WMFRiveImage: Data] = [:],
        readBool: WMFRiveBool? = nil,
        watchedTrigger: WMFRiveTrigger? = nil,
        watchedBool: WMFRiveBool? = nil,
        textFits: [WMFRiveTextFit] = [],
        loader: @escaping @MainActor (WMFRiveAnimation, WMFRiveBindingsMaker) async throws -> Rive = WMFRiveWorkerProvider.makeRive,
        imageDecoder: @escaping @MainActor (Data) async throws -> RiveRuntime.Image = WMFRiveWorkerProvider.decodeImage
    ) {
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.bools = bools
        self.images = images
        self.readBool = readBool
        self.watchedTrigger = watchedTrigger
        self.watchedBool = watchedBool
        self.textFits = textFits
        self.loader = loader
        self.imageDecoder = imageDecoder
    }

    deinit {
        loadTask?.cancel()
        imageTask?.cancel()
        triggerTask?.cancel()
        boolTask?.cancel()
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

    /// Makes a new state machine, so the animation plays again from its first frame. A state machine
    /// cannot go back to its start. The animation on screen stays until the new one is ready.
    @discardableResult
    func restart() -> Task<Void, Never>? {
        guard loadState.isLoaded else { return nil }
        loadTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.load(showsLoading: false)
        }
        loadTask = task
        return task
    }

    /// - Parameter showsLoading: `false` keeps the current animation on screen during the load.
    func load(showsLoading: Bool = true) async {
        if showsLoading {
            loadState = .loading
        }
        do {
            var made: Bound?
            let rive = try await loader(animation) { file, artboard in
                let bound = await self.makeBound(file: file, artboard: artboard)
                made = bound
                return bound.bindings
            }
            guard !Task.isCancelled else { return }
            self.rive = rive
            self.bound = made
            if let made, made.text != text || made.numbers != numbers || made.bools != bools || made.enums != enums {
                // The values changed while the file loaded.
                applyCurrentValues()
            }
            validatePathsInDebug()
            applyImages()
            watchTrigger()
            watchBool()
            self.loadState = .loaded
            await readBoolFromFile()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.rive = nil
            self.bound = nil
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
        triggerTask?.cancel()
        triggerTask = nil
        boolTask?.cancel()
        boolTask = nil
        rive = nil
        bound = nil
        readBoolValue = nil
        loadState = .idle
    }

    /// Writes the new values on the instances that are bound. It does not bind new instances. See `makeBound`.
    func update(text newText: [WMFRiveText: String], numbers newNumbers: [WMFRiveNumber: Double]) {
        guard newText != text || newNumbers != numbers else { return }
        text = newText
        numbers = newNumbers
        applyCurrentValues()
    }

    func update(bools newBools: [WMFRiveBool: Bool]) {
        guard newBools != bools else { return }
        bools = newBools
        applyCurrentValues()
    }

    /// Sets enum properties, for example the layout direction. Call it before `loadIfNeeded()` so the
    /// first frame already has the values.
    func update(enums newEnums: [WMFRiveEnum: String]) {
        guard newEnums != enums else { return }
        enums = newEnums
        applyCurrentValues()
    }

    func update(images newImages: [WMFRiveImage: Data]) {
        guard newImages != images else { return }
        images = newImages
        applyImages()
    }

    /// Makes the instances that the state machine binds when it is made, with the text and the fitted
    /// sizes already set. A script in the .riv gets its view models in its `init`, which runs when the
    /// state machine is made. The script does not see an instance that is bound after that, so it
    /// would lay out its glyphs for the size in the file, not the fitted size (T441488).
    private func makeBound(file: File, artboard: Artboard) async -> Bound {
        let main = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
        if let main {
            applyValues(to: main)
        }

        var globals: [String: ViewModelInstance] = [:]
        var fileSizes: [WMFRiveTextFit: FileSizes] = [:]
        for fit in textFits {
            do {
                let global: ViewModelInstance
                if let existing = globals[fit.globalViewModelName] {
                    global = existing
                } else {
                    global = try await file.createViewModelInstance(.viewModelDefault(from: .name(fit.globalViewModelName)))
                    globals[fit.globalViewModelName] = global
                }
                let fontSize = Double(try await global.value(of: NumberProperty(path: fit.fontSize.path)))
                let lineHeight = Double(try await global.value(of: NumberProperty(path: fit.lineHeight.path)))
                if let maximumFontSize = fit.maximumFontSize, fontSize > maximumFontSize {
                    fileSizes[fit] = FileSizes(fontSize: maximumFontSize, lineHeight: lineHeight * maximumFontSize / fontSize)
                } else {
                    fileSizes[fit] = FileSizes(fontSize: fontSize, lineHeight: lineHeight)
                }
            } catch {
                WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "Could not fit \"\(fit.text.path)\": \(error.localizedDescription)"))
            }
        }
        applyTextFits(to: globals, fileSizes: fileSizes)

        return Bound(main: main, globals: globals, fileSizes: fileSizes, text: text, numbers: numbers, bools: bools, enums: enums)
    }

    private func applyCurrentValues() {
        guard let bound else { return }
        if let main = bound.main {
            applyValues(to: main)
        }
        applyTextFits(to: bound.globals, fileSizes: bound.fileSizes)
    }

    private func applyValues(to instance: ViewModelInstance) {
        for (property, value) in text {
            instance.setValue(of: StringProperty(path: property.path), to: value)
        }
        for (property, value) in numbers {
            instance.setValue(of: NumberProperty(path: property.path), to: Float(value))
        }
        for (property, value) in bools {
            instance.setValue(of: BoolProperty(path: property.path), to: value)
        }
        for (property, value) in enums {
            instance.setValue(of: EnumProperty(path: property.path), to: value)
        }
    }

    /// A restart binds a new instance, so this watches the new instance.
    private func watchTrigger() {
        triggerTask?.cancel()
        guard let watchedTrigger, let instance = bound?.main else { return }
        let property = TriggerProperty(path: watchedTrigger.path)
        triggerTask = Task { [weak self] in
            do {
                for try await _ in instance.stream(of: property) {
                    guard let self, !Task.isCancelled else { return }
                    self.watchedEventCount += 1
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                WMFRiveLogger.log(WMFRiveFailure(animation: self.animation, stage: .binding, reason: "Could not watch \"\(watchedTrigger.path)\": \(error.localizedDescription)"))
            }
        }
    }

    /// A restart binds a new instance, so this watches the new instance. The stream can send the
    /// same value again, so only a change to true counts.
    private func watchBool() {
        boolTask?.cancel()
        guard let watchedBool, let instance = bound?.main else { return }
        let property = BoolProperty(path: watchedBool.path)
        boolTask = Task { [weak self] in
            do {
                var previousValue = false
                for try await value in instance.valueStream(of: property) {
                    guard let self, !Task.isCancelled else { return }
                    if value && !previousValue {
                        self.watchedEventCount += 1
                    }
                    previousValue = value
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                WMFRiveLogger.log(WMFRiveFailure(animation: self.animation, stage: .binding, reason: "Could not watch \"\(watchedBool.path)\": \(error.localizedDescription)"))
            }
        }
    }

    /// Decoding is async, so the images arrive after the text. An image that does not decode keeps
    /// the placeholder inside the .riv.
    private func applyImages() {
        imageTask?.cancel()
        guard let instance = bound?.main, !images.isEmpty else { return }
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

    /// Sets the size of each fit from the size in the file, also when the value fits, so a shorter
    /// value returns to the size in the file.
    private func applyTextFits(to globals: [String: ViewModelInstance], fileSizes: [WMFRiveTextFit: FileSizes]) {
        struct Measured {
            let fit: WMFRiveTextFit
            let global: ViewModelInstance
            let sizes: FileSizes
            let scale: Double
        }

        var measured: [Measured] = []
        for fit in textFits {
            guard let global = globals[fit.globalViewModelName], let sizes = fileSizes[fit] else { continue }
            var scale = 1.0
            if let value = text[fit.text], !value.isEmpty {
                guard let fitted = fit.scale(for: value, fontSize: sizes.fontSize) else {
                    WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: .binding, reason: "No system font for the asset \"\(fit.fontAssetName)\", so \"\(fit.text.path)\" is not fitted."))
                    continue
                }
                scale = fitted
            }
            measured.append(Measured(fit: fit, global: global, sizes: sizes, scale: scale))
        }

        // The runs of a group use the smallest scale of the group.
        var groupScales: [String: Double] = [:]
        for item in measured {
            guard let group = item.fit.group else { continue }
            groupScales[group] = min(groupScales[group] ?? 1, item.scale)
        }
        for item in measured {
            let scale = item.fit.group.flatMap { groupScales[$0] } ?? item.scale
            item.global.setValue(of: NumberProperty(path: item.fit.fontSize.path), to: Float(item.sizes.fontSize * scale))
            item.global.setValue(of: NumberProperty(path: item.fit.lineHeight.path), to: Float(item.sizes.lineHeight * scale))
        }
    }

    /// The app binds the default instance of the artboard. The templates set their flags on the
    /// instance that has the name of the artboard, so read that instance first.
    private func readBoolFromFile() async {
        guard let readBool, let rive else { return }
        let property = BoolProperty(path: readBool.path)
        var value: Bool?
        if let artboardName = animation.artboardName,
           let named = try? await rive.file.createViewModelInstance(.name(artboardName, from: .artboardDefault(rive.artboard))) {
            value = try? await named.value(of: property)
        }
        if value == nil, let main = bound?.main {
            value = try? await main.value(of: property)
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
        guard let instance = bound?.main, !text.isEmpty || !numbers.isEmpty else { return }
        let stringPaths = text.keys.map(\.path)
        let numberPaths = numbers.keys.map(\.path)
        Task { [animation] in
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
