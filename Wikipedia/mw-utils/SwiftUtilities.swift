//
//  SwiftUtilities.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 6/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

/// MARK: WrapperObject

/// Allows boxing of `Any` objects (including functions) for storage in `Any`-incompatible Foundation collections.
public class WrapperObject<T: Any> {
    var value: T

    public required init(value: T) {
        self.value = value
    }
}
