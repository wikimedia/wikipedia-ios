//  Created by Adam Baso on 2/14/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

@interface DownloadTitlesForRandomArticlesOp : MWNetworkOp

- (id)initForDomain: (NSString *)domain
    completionBlock: (void (^)(NSString *title))completionBlock
     cancelledBlock: (void (^)(NSError *))cancelledBlock
         errorBlock: (void (^)(NSError *))errorBlock
;

@end
