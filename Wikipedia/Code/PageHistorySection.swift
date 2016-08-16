//
//  PageHistorySection.swift
//  Wikipedia
//
//  Created by Nick DiStefano on 4/4/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

import Foundation


open class PageHistorySection: NSObject {
    open let sectionTitle: String
    open let items: [WMFPageHistoryRevision]
    
    public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}
