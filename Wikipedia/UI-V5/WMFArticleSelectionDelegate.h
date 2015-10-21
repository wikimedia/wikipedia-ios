//
//  WMFArticleSelectionDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKArticle;
@class WMFArticleContainerViewController;

@protocol WMFArticleSelectionDelegate <NSObject>

- (void)didSelectArticle:(MWKArticle*)article sender:(id)sender;

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender;

@end
