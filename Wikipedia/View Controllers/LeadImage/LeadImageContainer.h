//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "ThumbnailFetcher.h"

// Protocol for notifying delegate that lead image height changed.
@protocol LeadImageHeightDelegate <NSObject>
- (void)leadImageHeightChangedTo:(NSNumber*)height;
@end

@interface LeadImageContainer : UIControl <FetchFinishedDelegate>

- (void)showForArticle:(MWKArticle*)article;

@property (nonatomic, weak) id <LeadImageHeightDelegate> delegate;

@end
