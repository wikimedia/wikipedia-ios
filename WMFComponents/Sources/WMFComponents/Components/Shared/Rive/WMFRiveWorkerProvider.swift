import CoreText
import Foundation
import RiveRuntime
import UIKit

enum WMFRiveError: LocalizedError {
    case workerUnavailable

    var errorDescription: String? {
        switch self {
        case .workerUnavailable:
            return "Rive could not make a Metal worker on this device."
        }
    }
}

/// The view model instances that a state machine binds when it is made. A `nil` main instance, or a
/// global view model that is not in `globals`, gets the default instance of the file.
@MainActor
struct WMFRiveBindings {
    let main: ViewModelInstance?
    let globals: [String: ViewModelInstance]
}

/// Makes the instances to bind, after the file and the artboard load and before the state machine is made.
typealias WMFRiveBindingsMaker = @MainActor (File, Artboard) async -> WMFRiveBindings

@MainActor
enum WMFRiveWorkerProvider {

    private static var worker: Worker?
    private static var failure: (any Error)?
    private static var buildTask: Task<Void, Never>?
    private static var suppliedFontAssets: Set<String> = []

    // TEMPORARY: drop with the inventory dump below once the .riv paths are settled.
    private static var didDumpInventory = false

    /// The files export SF Pro, which the app must not bundle. Thus the app supplies the system font.
    private static let systemFontSubstitutions: [String: UIFont] = [
        "SanSerifFont": .systemFont(ofSize: 17, weight: .bold),
        // The list subtitles use this face. The export renames SF Pro Regular.
        "SanSerifFont-Regular": .systemFont(ofSize: 17, weight: .regular)
    ]

    /// A font file in the module bundle that the app supplies for a font asset of the .riv.
    private struct BundledFont {
        let resourceName: String
        let fileExtension: String
        /// The PostScript name in the file, to make a `UIFont` for text measurement.
        let postScriptName: String

        var url: URL? {
            Bundle.module.url(forResource: resourceName, withExtension: fileExtension)
        }
    }

    /// Linux Libertine, under the SIL Open Font License. The export renames it "SerifFont".
    private static let bundledFonts: [String: BundledFont] = [
        "SerifFont": BundledFont(resourceName: "SerifFont-Regular", fileExtension: "ttf", postScriptName: "SerifFont-Regular")
    ]

    private static var registeredBundledFonts: Set<String> = []

    /// The font that the app supplies for a font asset of the .riv, or `nil` if it supplies none.
    /// Text measurement uses it, so it is the same font that Rive draws.
    static func substituteFont(forAssetNamed name: String) -> UIFont? {
        if let systemFont = systemFontSubstitutions[name] {
            return systemFont
        }
        guard let bundledFont = bundledFonts[name] else {
            return nil
        }
        registerIfNeeded(bundledFont)
        return UIFont(name: bundledFont.postScriptName, size: 17)
    }

    /// Registers the font file for this process, so that `UIFont(name:size:)` can find it.
    private static func registerIfNeeded(_ bundledFont: BundledFont) {
        guard !registeredBundledFonts.contains(bundledFont.postScriptName),
              let url = bundledFont.url else {
            return
        }
        // A font that is already registered gives an error, but `UIFont(name:size:)` still finds it.
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        registeredBundledFonts.insert(bundledFont.postScriptName)
    }

    static func sharedWorker() async throws -> Worker {
        if let worker {
            return worker
        }

        if let buildTask {
            await buildTask.value
        } else {
            failure = nil
            let task = Task<Void, Never> {
                do {
                    worker = try await Worker()
                } catch {
                    worker = nil
                    failure = error
                }
            }
            buildTask = task
            await task.value
            buildTask = nil
        }

        if let worker {
            return worker
        }

        throw failure ?? WMFRiveError.workerUnavailable
    }

    /// Decodes image data on the worker that draws the files, so a view model can bind it.
    static func decodeImage(from data: Data) async throws -> RiveRuntime.Image {
        try await sharedWorker().decodeImage(from: data)
    }

    /// Loads the file and binds the instances from `bindings` when it makes the state machine.
    /// A `nil` artboard or state machine name gives the default of the file.
    ///
    /// Do not bind other instances after this. A script in the .riv gets its view models in its
    /// `init`, which runs when the state machine is made, and it keeps them. Write new values on the
    /// instances that `bindings` returned.
    static func makeRive(for animation: WMFRiveAnimation, bindings: WMFRiveBindingsMaker) async throws -> Rive {
        let worker = try await sharedWorker()
        let file = try await File(source: .local(animation.resourceName, .module), worker: worker)

        await supplyFonts(for: file, on: worker, animation: animation)

        #if DEBUG
        // TEMPORARY: prints the file's artboards, view models and property paths.
        await dumpInventory(of: file, named: animation.resourceName)
        #endif

        let artboard = try await file.createArtboard(animation.artboardName)
        let made = await bindings(file, artboard)
        let stateMachine = try await artboard.createStateMachine(animation.stateMachineName, binding: made.main) {
            for (name, instance) in made.globals {
                (name, instance)
            }
        }

        return try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            fit: .layout(scaleFactor: .automatic),
            backgroundColor: Color(red: 0, green: 0, blue: 0, alpha: 0)
        )
    }

    static func resourceExists(for animation: WMFRiveAnimation) -> Bool {
        return Bundle.module.url(forResource: animation.resourceName, withExtension: "riv") != nil
    }

    private static func supplyFonts(for file: File, on worker: Worker, animation: WMFRiveAnimation) async {
        let assets: [File.Asset]
        do {
            assets = try await file.getAssets()
        } catch {
            log(.font, animation, "Could not read the asset list: \(error.localizedDescription)")
            return
        }

        for asset in assets where asset.type == .font {
            guard !suppliedFontAssets.contains(asset.uniqueName) else { continue }

            do {
                let font: RiveRuntime.Font
                if let systemFont = systemFontSubstitutions[asset.name] {
                    font = try await worker.decodeFont(from: systemFont)
                } else if let url = bundledFonts[asset.name]?.url {
                    font = try await worker.decodeFont(from: Data(contentsOf: url))
                } else {
                    continue
                }
                worker.addGlobalFontAsset(font, name: asset.uniqueName)
                suppliedFontAssets.insert(asset.uniqueName)
            } catch {
                log(.font, animation, "Could not supply a font for \"\(asset.uniqueName)\": \(error.localizedDescription)")
            }
        }
    }

    private static func log(_ stage: WMFRiveFailure.Stage, _ animation: WMFRiveAnimation, _ reason: String) {
        WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: stage, reason: reason))
    }

    #if DEBUG
    // TEMPORARY: remove once the binding paths are recorded in the slide view models.
    private static func dumpInventory(of file: File, named resourceName: String) async {
        guard !didDumpInventory else { return }
        didDumpInventory = true

        func emit(_ line: String) {
            print("[RiveInventory] \(line)")
        }

        emit("file \"\(resourceName)\"")

        do {
            let artboardNames = try await file.getArtboardNames()
            emit("artboards: \(artboardNames)")

            for artboardName in artboardNames {
                let artboard = try await file.createArtboard(artboardName)
                let stateMachines = try await artboard.getStateMachineNames()
                let defaultInfo = try? await file.getDefaultViewModelInfo(for: artboard)
                let described = defaultInfo.map { "\($0.viewModelName) / \($0.instanceName)" } ?? "none"
                emit("  artboard \"\(artboardName)\" stateMachines=\(stateMachines) defaultViewModel=\(described)")
            }

            for viewModelName in try await file.getViewModelNames() {
                emit("  viewModel \"\(viewModelName)\"")
                for property in try await file.getProperties(of: viewModelName) {
                    emit("    \(property.name) : \(property.type) meta=\"\(property.metaData)\"")
                }
            }

            for viewModelEnum in try await file.getViewModelEnums() {
                emit("  enum \"\(viewModelEnum.name)\" = \(viewModelEnum.values)")
            }

            for asset in try await file.getAssets() {
                emit("  asset \"\(asset.uniqueName)\" type=\(asset.type) ext=\"\(asset.fileExtension)\" cdn=\(asset.cdn != nil)")
            }
        } catch {
            emit("failed: \(error)")
        }
    }
    #endif
}
