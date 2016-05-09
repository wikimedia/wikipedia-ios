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
    public let items: [WMFPageHistoryRevision]
    
    public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}