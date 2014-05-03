//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

@interface DownloadSectionWikiTextOp : MWNetworkOp

// Note: "section" parameter needs to be a string because the
// api returns transcluded section indexes with a "T-" prefix

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSString *)section
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
