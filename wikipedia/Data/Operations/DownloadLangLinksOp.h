//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

@interface DownloadLangLinksOp : MWNetworkOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
          allLanguages: (NSArray *)allLanguages
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
