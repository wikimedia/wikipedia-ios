import Dispatch
import Foundation.NSDate

/**
 @return A new promise that resolves after the specified duration.

 @parameter duration The duration in seconds to wait before this promise is resolve.

 For example:

    after(1).then {
        //…
    }
*/
public func after(delay: NSTimeInterval) -> Promise<Void> {
    return Promise { fulfill, _ in
        let delta = delay * NSTimeInterval(NSEC_PER_SEC)
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delta))
        dispatch_after(when, dispatch_get_global_queue(0, 0)) {
            fulfill()
        }
    }
}
import Foundation.NSError

/**
 AnyPromise is a Promise that can be used in Objective-C code

 Swift code can only convert Promises to AnyPromises or vice versa.

 Libraries that only provide promises will require you to write a
 small Swift function that can convert those promises into AnyPromises
 as you require them.

 To effectively use AnyPromise in Objective-C code you must use `#import`
 rather than `@import PromiseKit;`

     #import <PromiseKit/PromiseKit.h>
*/

/**
 Resolution.Fulfilled takes an Any. When retrieving the Any you cannot
 convert it into an AnyObject?. By giving Fulfilled an object that has
 an AnyObject? property we never have to cast and everything is fine.
*/
private class Box {
    let obj: AnyObject?
    
    init(_ obj: AnyObject?) {
        self.obj = obj
    }
}

private func box(obj: AnyObject?) -> Resolution {
    if let error = obj as? NSError {
        unconsume(error)
        return .Rejected(error)
    } else {
        return .Fulfilled(Box(obj))
    }
}

private func unbox(resolution: Resolution) -> AnyObject? {
    switch resolution {
    case .Fulfilled(let box):
        return (box as! Box).obj
    case .Rejected(let error):
        return error
    }
}



@objc(PMKAnyPromise) public class AnyPromise: NSObject {
    var state: State

    /**
     @return A new AnyPromise bound to a Promise<T>.

     The two promises represent the same task, any changes to either
     will instantly reflect on both.
    */
    public init<T: AnyObject>(bound: Promise<T>) {
        //WARNING copy pasta from below. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    public init<T: AnyObject>(bound: Promise<T?>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value!))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    /**
     @return A new AnyPromise bound to a Promise<[T]>.

     The two promises represent the same task, any changes to either
     will instantly reflect on both.
    
     The value is converted to an NSArray so Objective-C can use it.
    */
    public init<T: AnyObject>(bound: Promise<[T]>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(NSArray(array: bound.value!)))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    /**
    @return A new AnyPromise bound to a Promise<[T]>.

    The two promises represent the same task, any changes to either
    will instantly reflect on both.

    The value is converted to an NSArray so Objective-C can use it.
    */
    public init<T: AnyObject, U: AnyObject>(bound: Promise<[T:U]>) {
        //WARNING copy pasta from above. FIXME how?
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bound.pipe { resolution in
            switch resolution {
            case .Fulfilled:
                resolve(box(bound.value! as NSDictionary))
            case .Rejected(let error):
                resolve(box(error))
            }
        }
    }

    convenience public init(bound: Promise<Int>) {
        self.init(bound: bound.then(on: zalgo) { NSNumber(integer: $0) })
    }

    convenience public init(bound: Promise<Void>) {
        self.init(bound: bound.then(on: zalgo) { _ -> AnyObject? in return nil })
    }

    @objc init(@noescape bridge: ((AnyObject?) -> Void) -> Void) {
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        bridge { result in
            func preresolve(obj: AnyObject?) {
                resolve(box(obj))
            }
            if let next = result as? AnyPromise {
                next.pipe(preresolve)
            } else {
                preresolve(result)
            }
        }
    }

    @objc func pipe(body: (AnyObject?) -> Void) {
        state.get { seal in
            func prebody(resolution: Resolution) {
                body(unbox(resolution))
            }
            switch seal {
            case .Pending(let handlers):
                handlers.append(prebody)
            case .Resolved(let resolution):
                prebody(resolution)
            }
        }
    }

    @objc var __value: AnyObject? {
        if let resolution = state.get() {
            return unbox(resolution)
        } else {
            return nil
        }
    }

    /**
     A promise starts pending and eventually resolves.

     @return True if the promise has not yet resolved.
    */
    @objc public var pending: Bool {
        return state.get() == nil
    }

    /**
     A promise starts pending and eventually resolves.

     @return True if the promise has resolved.
    */
    @objc public var resolved: Bool {
        return !pending
    }

    /**
     A promise starts pending and eventually resolves.
    
     A fulfilled promise is resolved and succeeded.

     @return True if the promise was fulfilled.
    */
    @objc public var fulfilled: Bool {
        switch state.get() {
        case .Some(.Fulfilled):
            return true
        default:
            return false
        }
    }

    /**
     A promise starts pending and eventually resolves.
    
     A rejected promise is resolved and failed.

     @return True if the promise was rejected.
    */
    @objc public var rejected: Bool {
        switch state.get() {
        case .Some(.Rejected):
            return true
        default:
            return false
        }
    }

    // because you can’t access top-level Swift functions in objc
    @objc class func setUnhandledErrorHandler(body: (NSError) -> Void) -> (NSError) -> Void {
        let oldHandler = PMKUnhandledErrorHandler
        PMKUnhandledErrorHandler = body
        return oldHandler
    }
}


extension AnyPromise: DebugPrintable {
    override public var debugDescription: String {
        return "AnyPromise: \(state)"
    }
}
import Dispatch
import Foundation.NSError

public func dispatch_promise<T>(on queue: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> T) -> Promise<T> {
    return Promise { sealant in
        contain_zalgo(queue) {
            sealant.resolve(body())
        }
    }
}

// TODO Swift 1.2 thinks that usage of the following two is ambiguous
//public func dispatch_promise<T>(on queue: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> Promise<T>) -> Promise<T> {
//    return Promise { sealant in
//        contain_zalgo(queue) {
//            body().pipe(sealant.handler)
//        }
//    }
//}

public func dispatch_promise<T>(on: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> (T!, NSError!)) -> Promise<T> {
    return Promise{ (sealant: Sealant) -> Void in
        contain_zalgo(on) {
            let (a, b) = body()
            sealant.resolve(a, b)
        }
    }
}
import Foundation.NSError

/**
 The unhandled error handler.

 If a promise is rejected and no catch handler is called in its chain, the
 provided handler is called. The default handler logs the error.

    PMKUnhandledErrorHandler = { error in
        println("Unhandled error: \(error)")
    }

 @warning *Important* The handler is executed on an undefined queue.

 @warning *Important* Don’t use promises in your handler, or you risk an
 infinite error loop.

 @return The previous unhandled error handler.
*/
public var PMKUnhandledErrorHandler = { (error: NSError) -> Void in
    if !error.cancelled {
        NSLog("PromiseKit: Unhandled error: %@", error)
    }
}

private class Consumable: NSObject {
    let parentError: NSError
    var consumed: Bool = false

    deinit {
        if !consumed {
            PMKUnhandledErrorHandler(parentError)
        }
    }
    
    init(parent: NSError) {
        // we take a copy to avoid a retain cycle. A weak ref
        // is no good because then the error is deallocated
        // before we can call PMKUnhandledErrorHandler()
        parentError = parent.copy() as! NSError
    }
}

private var handle: UInt8 = 0

func consume(error: NSError) {
    let pmke = objc_getAssociatedObject(error, &handle) as! Consumable
    pmke.consumed = true
}

extension AnyPromise {
    // objc can't see Swift top-level function :(
    //TODO move this and the one in AnyPromise to a compat something
    @objc class func __consume(error: NSError) {
        consume(error)
    }
}

func unconsume(error: NSError) {
    if let pmke = objc_getAssociatedObject(error, &handle) as! Consumable? {
        pmke.consumed = false
    } else {
        // this is how we know when the error is deallocated
        // because we will be deallocated at the same time
        objc_setAssociatedObject(error, &handle, Consumable(parent: error), objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
}



private struct ErrorPair: Hashable {
    let domain: String
    let code: Int
    init(_ d: String, _ c: Int) {
        domain = d; code = c
    }
    var hashValue: Int {
        return "\(domain):\(code)".hashValue
    }
}

private func ==(lhs: ErrorPair, rhs: ErrorPair) -> Bool {
    return lhs.domain == rhs.domain && lhs.code == rhs.code
}

private var cancelledErrorIdentifiers = Set([
    ErrorPair(PMKErrorDomain, PMKOperationCancelled),
    ErrorPair(NSURLErrorDomain, NSURLErrorCancelled)
])

extension NSError {
    public class func cancelledError() -> NSError {
        let info: [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "The operation was cancelled"]
        return NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: info)
    }

    /**
      You may only call this on the main thread.
     */
    public class func registerCancelledErrorDomain(domain: String, code: Int) {
        cancelledErrorIdentifiers.insert(ErrorPair(domain, code))
    }

    public var cancelled: Bool {
        return cancelledErrorIdentifiers.contains(ErrorPair(domain, code))
    }
}
import Foundation

private func b0rkedEmptyRailsResponse() -> NSData {
    return NSData(bytes: " ", length: 1)
}

public func NSJSONFromData(data: NSData) -> Promise<NSArray> {
    if data == b0rkedEmptyRailsResponse() {
        return Promise(NSArray())
    } else {
        return NSJSONFromDataT(data)
    }
}

public func NSJSONFromData(data: NSData) -> Promise<NSDictionary> {
    if data == b0rkedEmptyRailsResponse() {
        return Promise(NSDictionary())
    } else {
        return NSJSONFromDataT(data)
    }
}

private func NSJSONFromDataT<T>(data: NSData) -> Promise<T> {
    var error: NSError?
    let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

    if let cast = json as? T {
        return Promise(cast)
    } else if let error = error {
        // NSJSONSerialization gives awful errors, so we wrap it
        let debug = error.userInfo!["NSDebugDescription"] as? String
        let description = "The server’s JSON response could not be decoded. (\(debug))"
        return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: [
            NSLocalizedDescriptionKey: "There was an error decoding the server’s JSON response.",
            NSUnderlyingErrorKey: error
        ]))
    } else {
        var info = [NSObject: AnyObject]()
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        info[PMKJSONErrorJSONObjectKey] = json
        return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: info))
    }
}
import Foundation.NSError

extension Promise {
    /**
     @return The error with which this promise was rejected; nil if this promise is not rejected.
    */
    public var error: NSError? {
        switch state.get() {
        case .None:
            return nil
        case .Some(.Fulfilled):
            return nil
        case .Some(.Rejected(let error)):
            return error
        }
    }

    /**
     @return `YES` if the promise has not yet resolved.
    */
    public var pending: Bool {
        return state.get() == nil
    }

    /**
     @return `YES` if the promise has resolved.
    */
    public var resolved: Bool {
        return !pending
    }

    /**
     @return `YES` if the promise was fulfilled.
    */
    public var fulfilled: Bool {
        return value != nil
    }

    /**
     @return `YES` if the promise was rejected.
    */
    public var rejected: Bool {
        return error != nil
    }
}
import Foundation.NSError

public let PMKOperationQueue = NSOperationQueue()

public enum CatchPolicy {
    case AllErrors
    case AllErrorsExceptCancellation
}

/**
 A promise represents the future value of a task.

 To obtain the value of a promise we call `then`.

 Promises are chainable: `then` returns a promise, you can call `then` on
 that promise, which  returns a promise, you can call `then` on that
 promise, et cetera.

 0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2.4.6.8.0.2
 Promises start in a pending state and *resolve* with a value to become
 *fulfilled* or with an `NSError` to become rejected.

 @see [PromiseKit `then` Guide](http://promisekit.org/then/)
 @see [PromiseKit Chaining Guide](http://promisekit.org/chaining/)
*/
public class Promise<T> {
    let state: State

    /**
     Create a new pending promise.

     Use this method when wrapping asynchronous systems that do *not* use
     promises so that they can be involved in promise chains.

     Don’t use this method if you already have promises! Instead, just return
     your promise!

     The closure you pass is executed immediately on the calling thread.

        func fetchKitten() -> Promise<UIImage> {
            return Promise { fulfill, reject in
                KittenFetcher.fetchWithCompletionBlock({ img, err in
                    if err == nil {
                        fulfill(img)
                    } else {
                        reject(err)
                    }
                })
            }
        }

     @param resolvers The provided closure is called immediately. Inside,
     execute your asynchronous system, calling fulfill if it suceeds and
     reject for any errors.

     @return A new promise.

     @warning *Note* If you are wrapping a delegate-based system, we recommend
     to use instead: defer

     @see http://promisekit.org/sealing-your-own-promises/
     @see http://promisekit.org/wrapping-delegation/
    */
    public convenience init(@noescape resolvers: (fulfill: (T) -> Void, reject: (NSError) -> Void) -> Void) {
        self.init(sealant: { sealant in
            resolvers(fulfill: sealant.resolve, reject: sealant.resolve)
        })
    }

    /**
     Create a new pending promise.

     This initializer is convenient when wrapping asynchronous systems that
     use common patterns. For example:

        func fetchKitten() -> Promise<UIImage> {
            return Promise { sealant in
                KittenFetcher.fetchWithCompletionBlock(sealant.resolve)
            }
        }

     @see Sealant
     @see init(resolvers:)
    */
    public init(@noescape sealant: (Sealant<T>) -> Void) {
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        sealant(Sealant(body: resolve))
    }

    /**
     Create a new fulfilled promise.
    */
    public init(_ value: T) {
        state = SealedState(resolution: .Fulfilled(value))
    }

    /**
     Create a new rejected promise.
    */
    public init(_ error: NSError) {
        unconsume(error)
        state = SealedState(resolution: .Rejected(error))
    }

    /**
      I’d prefer this to be the designated initializer, but then there would be no
      public designated unsealed initializer! Making this convenience would be
      inefficient. Not very inefficient, but still it seems distasteful to me.
     */
    init(passthru: ((Resolution) -> Void) -> Void) {
        var resolve: ((Resolution) -> Void)!
        state = UnsealedState(resolver: &resolve)
        passthru(resolve)
    }

    /**
     defer is convenient for wrapping delegates or larger asynchronous systems.

        class Foo: BarDelegate {
            let (promise, fulfill, reject) = Promise<Int>.defer()
    
            func barDidFinishWithResult(result: Int) {
                fulfill(result)
            }
    
            func barDidError(error: NSError) {
                reject(error)
            }
        }

     @return A tuple consisting of:

      1) A promise
      2) A function that fulfills that promise
      3) A function that rejects that promise
    */

    public class func defer() -> (promise: Promise, fulfill: (T) -> Void, reject: (NSError) -> Void) {
        var sealant: Sealant<T>!
        let promise = Promise { sealant = $0 }
        return (promise, sealant.resolve, sealant.resolve)
    }

    func pipe(body: (Resolution) -> Void) {
        state.get { seal in
            switch seal {
            case .Pending(let handlers):
                handlers.append(body)
            case .Resolved(let resolution):
                body(resolution)
            }
        }
    }

    private convenience init<U>(when: Promise<U>, body: (Resolution, (Resolution) -> Void) -> Void) {
        self.init(passthru: { resolve in
            when.pipe{ body($0, resolve) }
        })
    }

    /**
     The provided block is executed when this Promise is resolved.

     If you provide a block that takes a parameter, the value of the receiver will be passed as that parameter.

     @param on The queue on which body should be executed.

     @param body The closure that is executed when this Promise is fulfilled.

        [NSURLConnection GET:url].then(^(NSData *data){
            // do something with data
        });

     @return A new promise that is resolved with the value returned from the provided closure. For example:

        [NSURLConnection GET:url].then(^(NSData *data){
            return data.length;
        }).then(^(NSNumber *number){
            //…
        });

     @see thenInBackground
    */
    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) -> U) -> Promise<U> {
        return Promise<U>(when: self) { resolution, resolve in
            switch resolution {
            case .Rejected:
                resolve(resolution)
            case .Fulfilled(let value):
                contain_zalgo(q) {
                    resolve(.Fulfilled(body(value as! T)))
                }
            }
        }
    }

    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) -> Promise<U>) -> Promise<U> {
        return Promise<U>(when: self) { resolution, resolve in
            switch resolution {
            case .Rejected:
                resolve(resolution)
            case .Fulfilled(let value):
                contain_zalgo(q) {
                    body(value as! T).pipe(resolve)
                }
            }
        }
    }

    public func then(on q: dispatch_queue_t = dispatch_get_main_queue(), body: (T) -> AnyPromise) -> Promise<AnyObject?> {
        return Promise<AnyObject?>(when: self) { resolution, resolve in
            switch resolution {
            case .Rejected:
                resolve(resolution)
            case .Fulfilled(let value):
                contain_zalgo(q) {
                    let anypromise = body(value as! T)
                    anypromise.pipe { obj in
                        if let error = obj as? NSError {
                            resolve(.Rejected(error))
                        } else {
                            // possibly the value of this promise is a PMKManifold, if so
                            // calling the objc `value` method will return the first item.
                            let obj: AnyObject? = anypromise.valueForKey("value")
                            resolve(.Fulfilled(obj))
                        }
                    }
                }
            }
        }
    }

    /**
     The provided closure is executed on the default background queue when this Promise is fulfilled.

     This method is provided as a convenience for `then`.

     @see then
    */
    public func thenInBackground<U>(body: (T) -> U) -> Promise<U> {
        return then(on: dispatch_get_global_queue(0, 0), body)
    }

    public func thenInBackground<U>(body: (T) -> Promise<U>) -> Promise<U> {
        return then(on: dispatch_get_global_queue(0, 0), body)
    }

    /**
     The provided closure is executed when this Promise is rejected.

     Rejecting a promise cascades: rejecting all subsequent promises (unless
     recover is invoked) thus you will typically place your catch at the end
     of a chain. Often utility promises will not have a catch, instead
     delegating the error handling to the caller.

     The provided closure always runs on the main queue.

     @param policy The default policy does not execute your handler for
     cancellation errors. See registerCancellationError for more
     documentation.

     @param body The handler to execute when this Promise is rejected.

     @see registerCancellationError
    */
    public func catch(policy: CatchPolicy = .AllErrorsExceptCancellation, _ body: (NSError) -> Void) {
        pipe { resolution in
            switch resolution {
            case .Fulfilled:
                break
            case .Rejected(let error):
                if policy == .AllErrors || !error.cancelled {
                    dispatch_async(dispatch_get_main_queue()) {
                        consume(error)
                        body(error)
                    }
                }
            }
        }
    }

    /**
     The provided closure is executed when this Promise is rejected giving you
     an opportunity to recover from the error and continue the promise chain.
    */
    public func recover(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (NSError) -> Promise<T>) -> Promise<T> {
        return Promise(when: self) { resolution, resolve in
            switch resolution {
            case .Rejected(let error):
                contain_zalgo(q) {
                    consume(error)
                    body(error).pipe(resolve)
                }
            case .Fulfilled:
                resolve(resolution)
            }
        }
    }

    /**
     The provided closure is executed when this Promise is resolved.

     @param on The queue on which body should be executed.

     @param body The closure that is executed when this Promise is resolved.

         UIApplication.sharedApplication().networkActivityIndicatorVisible = true
         somePromise().then {
             //…
         }.finally {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
         }
    */
    public func finally(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: () -> Void) -> Promise<T> {
        return Promise(when: self) { resolution, resolve in
            contain_zalgo(q) {
                body()
                resolve(resolution)
            }
        }
    }
    
    /**
     @return The value with which this promise was fulfilled or nil if this
     promise is not fulfilled.
    */
    public var value: T? {
        switch state.get() {
        case .None:
            return nil
        case .Some(.Fulfilled(let value)):
            return (value as! T)
        case .Some(.Rejected):
            return nil
        }
    }
}


/**
 Zalgo is dangerous.

 Pass as the `on` parameter for a `then`. Causes the handler to be executed
 as soon as it is resolved. That means it will be executed on the queue it
 is resolved. This means you cannot predict the queue.

 In the case that the promise is already resolved the handler will be
 executed immediately.

 zalgo is provided for libraries providing promises that have good tests
 that prove unleashing zalgo is safe. You can also use it in your
 application code in situations where performance is critical, but be
 careful: read the essay at the provided link to understand the risks.

 @see http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony
*/
public let zalgo: dispatch_queue_t = dispatch_queue_create("Zalgo", nil)

/**
 Waldo is dangerous.

 Waldo is zalgo, unless the current queue is the main thread, in which case
 we dispatch to the default background queue.

 If your block is likely to take more than a few milliseconds to execute,
 then you should use waldo: 60fps means the main thread cannot hang longer
 than 17 milliseconds. Don’t contribute to UI lag.

 Conversely if your then block is trivial, use zalgo: GCD is not free and
 for whatever reason you may already be on the main thread so just do what
 you are doing quickly and pass on execution.

 It is considered good practice for asynchronous APIs to complete onto the
 main thread. Apple do not always honor this, nor do other developers.
 However, they *should*. In that respect waldo is a good choice if your
 then is going to take a while and doesn’t interact with the UI.

 Please note (again) that generally you should not use zalgo or waldo. The
 performance gains are neglible and we provide these functions only out of
 a misguided sense that library code should be as optimized as possible.
 If you use zalgo or waldo without tests proving their correctness you may
 unwillingly introduce horrendous, near-impossible-to-trace bugs.

 @see zalgo
*/
public let waldo: dispatch_queue_t = dispatch_queue_create("Waldo", nil)

func contain_zalgo(q: dispatch_queue_t, block: () -> Void) {
    if q === zalgo {
        block()
    } else if q === waldo {
        if NSThread.isMainThread() {
            dispatch_async(dispatch_get_global_queue(0, 0), block)
        } else {
            block()
        }
    } else {
        dispatch_async(q, block)
    }
}


extension Promise {
    /**
     Creates a rejected Promise with `PMKErrorDomain` and a specified localizedDescription and error code.
    */
    public convenience init(error: String, code: Int = PMKUnexpectedError) {
        let error = NSError(domain: "PMKErrorDomain", code: code, userInfo: [NSLocalizedDescriptionKey: error])
        self.init(error)
    }
    
    /**
     Promise<Any> is more flexible, and often needed. However Swift won't cast
     <T> to <Any> directly. Once that is possible we will deprecate this
     function.
    */
    public func asAny() -> Promise<Any> {
        return Promise<Any>(passthru: pipe)
    }

    /**
     Promise<AnyObject> is more flexible, and often needed. However Swift won't
     cast <T> to <AnyObject> directly. Once that is possible we will deprecate
     this function.
    */
    public func asAnyObject() -> Promise<AnyObject> {
        return Promise<AnyObject>(passthru: pipe)
    }

    /**
     Swift (1.2) seems to be much less fussy about Void promises.
    */
    public func asVoid() -> Promise<Void> {
        return then(on: zalgo) { _ in return }
    }
}


extension Promise: DebugPrintable {
    public var debugDescription: String {
        return "Promise: \(state)"
    }
}

/**
 Firstly can make chains more readable.

 Compare:

    NSURLConnection.GET(url1).then {
        NSURLConnection.GET(url2)
    }.then {
        NSURLConnection.GET(url3)
    }

 With:

    firstly {
        NSURLConnection.GET(url1)
    }.then {
        NSURLConnection.GET(url2)
    }.then {
        NSURLConnection.GET(url3)
    }
*/
public func firstly<T>(promise: () -> Promise<T>) -> Promise<T> {
    return promise()
}

public func race<T>(promises: Promise<T>...) -> Promise<T> {
    return Promise(passthru: { resolve in
        for promise in promises {
            promise.pipe(resolve)
        }
    })
}
import Foundation.NSError

public class Sealant<T> {
    let handler: (Resolution) -> ()

    init(body: (Resolution) -> Void) {
        handler = body
    }

    /** internal because it is dangerous */
    func __resolve(obj: AnyObject) {
        switch obj {
        case is NSError:
            resolve(obj as! NSError)
        default:
            handler(.Fulfilled(obj))
        }
    }

    public func resolve(value: T) {
        handler(.Fulfilled(value))
    }

    public func resolve(error: NSError!) {
        unconsume(error)
        handler(.Rejected(error))
    }

    /**
     Makes wrapping (typical) asynchronous patterns easy.

     For example, here we wrap an `MKLocalSearch`:

         func search() -> Promise<MKLocalSearchResponse> {
             return Promise { sealant in
                 MKLocalSearch(request: …).startWithCompletionHandler(sealant.resolve)
             }
         }

     To get this to work you often have to help the compiler by specifiying
     the type. In future versions of Swift, this should become unecessary.
    */
    public func resolve(obj: T!, var _ error: NSError!) {
        if obj != nil {
            handler(.Fulfilled(obj))
        } else if error != nil {
            resolve(error)
        } else {
            //FIXME couldn't get the constants from the umbrella header :(
            error = NSError(domain: PMKErrorDomain, code: /*PMKUnexpectedError*/ 1, userInfo: nil)
            resolve(error)
        }
    }
    
    public func resolve(obj: T, _ error: NSError!) {
        if error == nil {
            handler(.Fulfilled(obj))
        } else  {
            resolve(error)
        }
    }

    /**
     Provided for APIs that *still* return [AnyObject] because they suck.
     FIXME fails
    */
//    public func convert(objects: [AnyObject]!, _ error: NSError!) {
//        if error != nil {
//            resolve(error)
//        } else {
//            handler(.Fulfilled(objects))
//        }
//    }

    /**
     For the case where T is Void. If it isn’t stuff will crash at some point.
     FIXME crashes when T is Void and .Fulfilled contains Void. Fucking sigh.
    */
//    public func ignore<U>(obj: U, _ error: NSError!) {
//        if error == nil {
//            handler(.Fulfilled(T))
//        } else {
//            resolve(error)
//        }
//    }
}
import Foundation.NSError

enum Resolution {
    case Fulfilled(Any)    //TODO make type T when Swift can handle it
    case Rejected(NSError)
}

enum Seal {
    case Pending(Handlers)
    case Resolved(Resolution)
}

protocol State {
    func get() -> Resolution?
    func get(body: (Seal) -> Void)
}

class UnsealedState: State {
    private let barrier = dispatch_queue_create("org.promisekit.barrier", DISPATCH_QUEUE_CONCURRENT)
    private var seal: Seal

    /**
     Quick return, but will not provide the handlers array
     because it could be modified while you are using it by
     another thread. If you need the handlers, use the second
     `get` variant.
    */
    func get() -> Resolution? {
        var result: Resolution?
        dispatch_sync(barrier) {
            switch self.seal {
            case .Resolved(let resolution):
                result = resolution
            case .Pending:
                break
            }
        }
        return result
    }

    func get(body: (Seal) -> Void) {
        var sealed = false
        dispatch_sync(barrier) {
            switch self.seal {
            case .Resolved:
                sealed = true
            case .Pending:
                sealed = false
            }
        }
        if !sealed {
            dispatch_barrier_sync(barrier) {
                switch (self.seal) {
                case .Pending:
                    body(self.seal)
                case .Resolved:
                    sealed = true  // welcome to race conditions
                }
            }
        }
        if sealed {
            body(seal)
        }
    }

    init(inout resolver: ((Resolution) -> Void)!) {
        seal = .Pending(Handlers())
        resolver = { resolution in
            var handlers: Handlers?
            dispatch_barrier_sync(self.barrier) {
                switch self.seal {
                case .Pending(let hh):
                    self.seal = .Resolved(resolution)
                    handlers = hh
                case .Resolved:
                    break
                }
            }
            if let handlers = handlers {
                for handler in handlers {
                    handler(resolution)
                }
            }
        }
    }
}

class SealedState: State {
    private let resolution: Resolution
    
    init(resolution: Resolution) {
        self.resolution = resolution
    }
    
    func get() -> Resolution? {
        return resolution
    }
    func get(body: (Seal) -> Void) {
        body(.Resolved(resolution))
    }
}


class Handlers: SequenceType {
    var bodies: [(Resolution)->()] = []

    func append(body: (Resolution)->()) {
        bodies.append(body)
    }

    func generate() -> IndexingGenerator<[(Resolution)->()]> {
        return bodies.generate()
    }

    var count: Int {
        return bodies.count
    }
}


extension Resolution: DebugPrintable {
    var debugDescription: String {
        switch self {
        case Fulfilled(let value):
            return "Fulfilled with value: \(value)"
        case Rejected(let error):
            return "Rejected with error: \(error)"
        }
    }
}

extension UnsealedState: DebugPrintable {
    var debugDescription: String {
        var rv: String?
        get { seal in
            switch seal {
            case .Pending(let handlers):
                rv = "Pending with \(handlers.count) handlers"
            case .Resolved(let resolution):
                rv = "\(resolution)"
            }
        }
        return "UnsealedState: \(rv!)"
    }
}

extension SealedState: DebugPrintable {
    var debugDescription: String {
        return "SealedState: \(resolution)"
    }
}
import Foundation.NSProgress

private func when<T>(promises: [Promise<T>]) -> Promise<Void> {
    let (rootPromise, fulfill, reject) = Promise<Void>.defer()
#if !PMKDisableProgress
    let progress = NSProgress(totalUnitCount: Int64(promises.count))
    progress.cancellable = false
    progress.pausable = false
#else
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#endif
    var countdown = promises.count

    for (index, promise) in enumerate(promises) {
        promise.pipe { resolution in
            if rootPromise.pending {
                switch resolution {
                case .Rejected(let error):
                    progress.completedUnitCount = progress.totalUnitCount
                    //TODO PMKFailingPromiseIndexKey
                    reject(error)
                case .Fulfilled:
                    progress.completedUnitCount++
                    if --countdown == 0 {
                        fulfill()
                    }
                }
            }
        }
    }

    return rootPromise
}

public func when<T>(promises: [Promise<T>]) -> Promise<[T]> {
    return when(promises).then(on: zalgo) { promises.map{ $0.value! } }
}

public func when<T>(promises: Promise<T>...) -> Promise<[T]> {
    return when(promises)
}

public func when(promises: Promise<Void>...) -> Promise<Void> {
    return when(promises)
}

public func when<U, V>(pu: Promise<U>, pv: Promise<V>) -> Promise<(U, V)> {
    return when(pu.asVoid(), pv.asVoid()).then(on: zalgo) { (pu.value!, pv.value!) }
}

public func when<U, V, X>(pu: Promise<U>, pv: Promise<V>, px: Promise<X>) -> Promise<(U, V, X)> {
    return when(pu.asVoid(), pv.asVoid(), px.asVoid()).then(on: zalgo) { (pu.value!, pv.value!, px.value!) }
}

@availability(*, unavailable, message="Use `when`")
public func join<T>(promises: Promise<T>...) {}
let PMKErrorDomain = "PMKErrorDomain"
let PMKFailingPromiseIndexKey = "PMKFailingPromiseIndexKey"
let PMKURLErrorFailingURLResponseKey = "PMKURLErrorFailingURLResponseKey"
let PMKURLErrorFailingDataKey = "PMKURLErrorFailingDataKey"
let PMKURLErrorFailingStringKey = "PMKURLErrorFailingStringKey"
let PMKJSONErrorJSONObjectKey = "PMKJSONErrorJSONObjectKey"
let PMKUnexpectedError = 1
let PMKUnknownError = 2
let PMKInvalidUsageError = 3
let PMKAccessDeniedError = 4
let PMKOperationCancelled = 5
let PMKNotFoundError = 6
let PMKJSONError = 7
let PMKOperationFailed = 8
let PMKTaskError = 9
let PMKTaskErrorLaunchPathKey = "PMKTaskErrorLaunchPathKey"
let PMKTaskErrorArgumentsKey = "PMKTaskErrorArgumentsKey"
let PMKTaskErrorStandardOutputKey = "PMKTaskErrorStandardOutputKey"
let PMKTaskErrorStandardErrorKey = "PMKTaskErrorStandardErrorKey"
let PMKTaskErrorExitStatusKey = "PMKTaskErrorExitStatusKey"
