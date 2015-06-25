//
//  CancellablePromise.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

public class CancellablePromise<T>: Promise<T>, Cancellable {
    var reject: ((NSError) -> Void)!

    public override class func defer() -> (promise: CancellablePromise<T>, fulfill: (T) -> Void, reject: (NSError) -> Void) {
        var sealant: Sealant<T>!
        let promise = CancellablePromise { sealant = $0 }
        promise.reject = sealant.resolve
        return (promise, sealant.resolve, sealant.resolve)
    }

    public override init(@noescape sealant: (Sealant<T>) -> Void) {
        super.init(sealant: sealant)
    }

    public func cancel() {
        reject(NSError.cancelledError())
    }
}

extension Promise {

    public func whenResolvedOrCancelled(then: ()->Void) {
        self.pipe() { resolution in
            switch resolution {
            case .Fulfilled:
                then()
            case .Rejected(let error):
                if error.cancelled {
                    then()
                }
            }
        }
    }

    public func blockResolutionIfResolved<U>(promise: Promise<U>) -> Promise<T> {
        return self.then() { value in
            if promise.resolved {
                return Promise(NSError.cancelledError())
            } else {
                return Promise(value)
            }
        }
    }
}
