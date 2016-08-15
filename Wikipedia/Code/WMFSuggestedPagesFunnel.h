//
//  SuggestedPagesFunnel.h
//  Wikipedia
//
//  Created by Adam Baso on 2/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "EventLoggingFunnel.h"

@interface WMFSuggestedPagesFunnel : EventLoggingFunnel

- (id)initWithArticle:(MWKArticle *)article
      suggestedTitles:(NSArray *)suggestedTitles;
- (void)logShown;
- (void)logClickedAtIndex:(NSUInteger)index;

@end
