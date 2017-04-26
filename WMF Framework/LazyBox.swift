// https://oleb.net/blog/2015/12/lazy-properties-in-structs-swift/

private enum LazyValue<T> {
    case NotYetComputed(() -> T)
    case Computed(T)
}

final class LazyBox<T> {
    init(computation: @escaping () -> T) {
        _value = .NotYetComputed(computation)
    }
    
    private var _value: LazyValue<T>
    
    var value: T {
        switch self._value {
        case .NotYetComputed(let computation):
            let result = computation()
            self._value = .Computed(result)
            return result
        case .Computed(let result):
            return result
        }
    }
}
