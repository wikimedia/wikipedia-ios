import Foundation
import RiveRuntime

enum WMFRiveError: LocalizedError {
    case workerUnavailable

    var errorDescription: String? {
        switch self {
        case .workerUnavailable:
            return "Rive could not make a Metal worker on this device."
        }
    }
}

@MainActor
enum WMFRiveWorkerProvider {

    private static var worker: Worker?
    private static var failure: (any Error)?
    private static var buildTask: Task<Void, Never>?

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

    static func makeRive(for animation: WMFRiveAnimation) async throws -> Rive {
        let worker = try await sharedWorker()
        let file = try await File(source: .local(animation.resourceName, .module), worker: worker)

        var artboard: Artboard?
        var stateMachine: StateMachine?

        if animation.artboardName != nil || animation.stateMachineName != nil {
            let resolved = try await file.createArtboard(animation.artboardName)
            artboard = resolved
            if let stateMachineName = animation.stateMachineName {
                stateMachine = try await resolved.createStateMachine(stateMachineName)
            }
        }

        return try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .auto,
            fit: .contain(alignment: .center),
            backgroundColor: Color(red: 0, green: 0, blue: 0, alpha: 0)
        )
    }

    static func resourceExists(for animation: WMFRiveAnimation) -> Bool {
        return Bundle.module.url(forResource: animation.resourceName, withExtension: "riv") != nil
    }
}
