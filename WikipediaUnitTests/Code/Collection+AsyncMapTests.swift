import Foundation
import Testing
import UIKit

struct CollectionAsyncMapTests {

    @Test
    func asyncMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() async {
        let inputItems = ["THIS", "THAT", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]

        let asyncItemTransformer = { (item: String, completion: @escaping (String) -> Void) in
            // Fake a process which returns results out of collection order.
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }

        let results = await withCheckedContinuation { continuation in
            inputItems.asyncMap(asyncItemTransformer) { results in
                continuation.resume(returning: results)
            }
        }

        #expect(results == expectedOutputItems)
    }

    @Test
    func asyncCompactMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() async {
        let inputItems = ["THIS", "MAP_TO_NIL", "THAT", "MAP_TO_NIL", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]

        let asyncItemTransformer = { (item: String, completion: @escaping (String?) -> Void) in
            // Fake a process which returns results out of collection order.
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                guard item != "MAP_TO_NIL" else {
                    completion(nil)
                    return
                }
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }

        let results = await withCheckedContinuation { continuation in
            inputItems.asyncCompactMap(asyncItemTransformer) { results in
                continuation.resume(returning: results)
            }
        }

        #expect(results == expectedOutputItems)
    }

    @Test
    func asyncForEachPerformsBlockForEachItem() async {
        let inputItems = ["THIS", "THAT", "OTHER"]
        let expectedResults = Set(arrayLiteral: "THIS", "OTHER", "THAT")
        let results = AsyncForEachResults()

        let asyncItemBlock = { (item: String, completion: @escaping () -> Void) in
            // Fake a process which completes out of collection order.
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                Task {
                    await results.insert(item)
                    completion()
                }
            }
        }

        await withCheckedContinuation { continuation in
            inputItems.asyncForEach(asyncItemBlock) {
                continuation.resume()
            }
        }

        #expect(await results.snapshot() == expectedResults)
    }

    @Test
    func asyncMapToDictionary() async {
        let input = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let expectedOutput = ["A":"a", "B":"b", "C":"c", "D":"d", "E":"e", "F":"f", "G":"g", "H":"h"]

        let result = await withCheckedContinuation { continuation in
            input.asyncMapToDictionary(block: { input, completion in
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                    completion(input, input.lowercased())
                }
            }, queue: DispatchQueue.main) { output in
                continuation.resume(returning: (output, Thread.isMainThread))
            }
        }

        #expect(result.1)
        #expect(result.0 == expectedOutput)
    }

    @Test
    func asyncMapToDictionaryWithLargeInput() async {
        let count = 10000
        var input = [Int]()
        input.reserveCapacity(count)
        var expectedOutput = [Int:Int]()
        expectedOutput.reserveCapacity(count)
        let transform = { (i: Int) in return i * i }
        for i in 1...count {
            input.append(i)
            expectedOutput[i] = transform(i)
        }

        let result = await withCheckedContinuation { continuation in
            input.asyncMapToDictionary(block: { input, completion in
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                    completion(input, transform(input))
                }
            }, queue: DispatchQueue.main) { output in
                continuation.resume(returning: (output, Thread.isMainThread))
            }
        }

        #expect(result.1)
        #expect(result.0 == expectedOutput)
    }

    @Test
    func largeAsyncMap() async {
        let randomDelayBlock: (String, @escaping (String) -> Void) -> Void = { string, completion in
            let randomMillisecondDelay = DispatchTimeInterval.milliseconds(Int.random(in: 1...10))
            let time = DispatchTime.now() + randomMillisecondDelay
            DispatchQueue.global(qos: .default).asyncAfter(deadline: time) {
                completion(string)
            }
        }
        let count = 1000
        var identifiers: [String] = []
        identifiers.reserveCapacity(count)
        for _ in 1...count {
            identifiers.append(UUID().uuidString)
        }

        let processedIdentifiers = await withCheckedContinuation { continuation in
            identifiers.asyncMap(randomDelayBlock) { processedIdentifiers in
                continuation.resume(returning: processedIdentifiers)
            }
        }

        #expect(processedIdentifiers == identifiers)
    }

    @Test
    func largeAsyncCompactMap() async {
        let randomDelayBlock: (String, @escaping (String?) -> Void) -> Void = { string, completion in
            let randomMillisecondDelay = DispatchTimeInterval.milliseconds(Int.random(in: 1...10))
            let time = DispatchTime.now() + randomMillisecondDelay
            DispatchQueue.global(qos: .default).asyncAfter(deadline: time) {
                completion(string.hasPrefix("A") ? nil : string)
            }
        }
        let count = 1000
        var identifiers: [String] = []
        identifiers.reserveCapacity(count)
        for _ in 1...count {
            identifiers.append(UUID().uuidString)
        }

        let processedIdentifiers = await withCheckedContinuation { continuation in
            identifiers.asyncCompactMap(randomDelayBlock) { processedIdentifiers in
                continuation.resume(returning: processedIdentifiers)
            }
        }

        #expect(processedIdentifiers.filter { $0.hasPrefix("A") }.isEmpty)
    }
}

private actor AsyncForEachResults {
    private var values: Set<String> = []

    func insert(_ value: String) {
        values.insert(value)
    }

    func snapshot() -> Set<String> {
        values
    }
}
