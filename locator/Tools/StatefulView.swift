import Foundation
import UIKit
import Combine

/// Some UI object which renders from one state onbject
protocol StatefulView<State>: AnyObject {
    
    associatedtype State
    typealias StatePublisher = AnyPublisher<State, Never>

    var bag: Set<AnyCancellable> { get set }
    
    /// Attach stete updates to apply(state:) func
    func bind(state: StatePublisher)
    
    /// Call when view loaded
    var onLoad: (() -> Void)? { get set }
    
    /// Setup initial view state if needed
    func prepareView()
    
    /// Perform state diff rendering
    func apply(state: State)
}

extension StatefulView where Self: UIView {
    func bind(state: StatePublisher) {
        prepareView()
        state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.apply(state: state)
            }
            .store(in: &bag)
    }
}

extension StatefulView where Self: UIViewController {
    func bind(state: StatePublisher) {
        onLoad = { [weak self] in
            guard let self = self else { return }
            self.prepareView()
            state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.apply(state: state)
                }
                .store(in: &self.bag)
        }
    }
}
