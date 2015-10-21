//
//  WMFArticleSelectionDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWKHistoryEntry.h"

@class MWKTitle;
@class WMFArticleContainerViewController;

@protocol WMFArticleSelectionDelegate <NSObject>

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender;

@end
