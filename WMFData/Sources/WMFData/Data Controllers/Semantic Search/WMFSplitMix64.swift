import Foundation

/// SplitMix64 pseudo random number generator, as defined in the Team-Draft merge spec shared with
/// Android. It drives every coin flip of the merge, so it must give the same outputs as Android's
/// `SplitMix64` for the same seed. Do not replace it with a platform generator.
///
/// All arithmetic is unsigned 64-bit and wraps on overflow.
public struct WMFSplitMix64: Sendable {
    private var state: UInt64

    private static let goldenGamma: UInt64 = 0x9E3779B97F4A7C15
    private static let mixMultiplier1: UInt64 = 0xBF58476D1CE4E5B9
    private static let mixMultiplier2: UInt64 = 0x94D049BB133111EB

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func nextUInt64() -> UInt64 {
        state &+= Self.goldenGamma
        var z = state
        z = (z ^ (z >> 30)) &* Self.mixMultiplier1
        z = (z ^ (z >> 27)) &* Self.mixMultiplier2
        return z ^ (z >> 31)
    }

    /// The top bit of the next output: 0 means lexical picks first, 1 means semantic picks first.
    public mutating func nextCoin() -> Int {
        return Int(nextUInt64() >> 63)
    }
}
