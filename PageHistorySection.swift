//
//  PageHistorySection.swift
//  Wikipedia
//
//  Created by Nick DiStefano on 4/4/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

import Foundation


public class PageHistorySection: NSObject {
    public let sectionTitle: String
    public private(set) var items = [WMFPageHistoryRevision]()
    
    public init(sectionTitle: String) {
        self.sectionTitle = sectionTitle
    }
    
    public func addItem(item: WMFPageHistoryRevision) {
        items.append(item)
    }
}