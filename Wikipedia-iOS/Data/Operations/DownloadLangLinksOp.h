//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface DownloadLangLinksOp : MWNetworkOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
          allLanguages: (NSMutableArray *)allLanguages
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
