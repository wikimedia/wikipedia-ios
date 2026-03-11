import Foundation

public class InstrumentImpl {
    public let name: String
    private weak var client: TestKitchenClient?
    public var funnel: Funnel?
    public var experiment: ExperimentImpl?
    private var defaultActionSource: String?

    init(name: String, client: TestKitchenClient? = nil) {
        self.name = name
        self.client = client
    }

    @discardableResult
    public func submitInteraction(
        action: String,
        actionSource: String? = nil,
        actionSubtype: String? = nil,
        elementId: String? = nil,
        elementFriendlyName: String? = nil,
        actionContext: [String: Any]? = nil
    ) -> InstrumentImpl {
        if experiment?.isLoggable?() == false {
            return self
        }

        var actionContextFinal: [String: String] = [:]
        funnel?.addActionContext(&actionContextFinal)
        if let actionContext {
            for (key, value) in actionContext {
                actionContextFinal[key] = String(describing: value)
            }
        }

        let actionContextString: String?
        if !actionContextFinal.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: actionContextFinal),
           let string = String(data: data, encoding: .utf8) {
            actionContextString = string
        } else {
            actionContextString = nil
        }

        client?.submitInteraction(
            instrument: self,
            interactionData: InteractionData(
                action: action,
                actionSubtype: actionSubtype,
                actionSource: actionSource ?? defaultActionSource,
                actionContext: actionContextString,
                elementId: elementId,
                elementFriendlyName: elementFriendlyName
            )
        )

        funnel?.touch()
        return self
    }

    @discardableResult
    public func startFunnel(name: String? = nil) -> InstrumentImpl {
        funnel = Funnel(name: name)
        return self
    }

    @discardableResult
    public func stopFunnel() -> InstrumentImpl {
        funnel = nil
        return self
    }

    @discardableResult
    public func setExperiment(_ experiment: ExperimentImpl?) -> InstrumentImpl {
        self.experiment = experiment
        return self
    }

    @discardableResult
    public func setDefaultActionSource(_ source: String) -> InstrumentImpl {
        defaultActionSource = source
        return self
    }
}
