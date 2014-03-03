//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface PreviewWikiTextOp : MWNetworkOp

- (id)initWithDomain: (NSString *)domain
               title: (NSString *)title
            wikiText: (NSString *)wikiText
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
