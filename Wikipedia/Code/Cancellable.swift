//
//  Cancellable.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

@objc
public protocol Cancellable {
    func cancel() -> Void
}

extension Operation: Cancellable {}

extension NSURLConnection: Cancellable {}

extension URLSessionTask: Cancellable {}
