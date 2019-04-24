//
//  TalkPageTestHelpers.swift
//  Wikipedia
//
//  Created by Toni Sevener on 4/23/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
@testable import WMF

class TalkPageTestHelpers {
    
    static func networkTalkPage(for urlString: String, talkPageString: String = "TalkPage") -> NetworkTalkPage? {
        let session = Session.shared
        //todo: better bundle pulling
        guard let json = Bundle(identifier: "org.wikimedia.WikipediaUnitTests")?.wmf_data(fromContentsOfFile: talkPageString, ofType: "json") else {
            return nil
        }
        do {
            let result: NetworkTalkPage = try session.jsonDecodeData(data: json)
            result.url = URL(string: urlString)
            return result
        } catch {
            return nil
        }
    }
    
}
