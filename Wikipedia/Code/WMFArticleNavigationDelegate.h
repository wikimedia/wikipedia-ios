//
//  WMFArticleNavigationDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFArticleNavigation.h"

@class MWKTitle;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFArticleNavigationDelegate <NSObject>

/*
   TODO: remove __nullable, as it's only nullable to allow edge cases where there's no sender at the call site
   which conforms to the protocol. Most delegates won't see `nil` since a "proxy" object will forward the delegate
   callback, passing themselves as the sender.
 */

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender didTapLinkToPage:(MWKTitle*)pageTitle;

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender didTapCitationLink:(NSString*)citationFragment;

- (void)articleNavigator:(id<WMFArticleNavigation> __nullable)sender didTapExternalLink:(NSURL*)externalURL;

/*
   Note for the future: gallery presentation should be based on:
   - article (or maybe section)
   - current image
   - rect of tapped image in screen bounds (for "zoom in" transition to modal)
 */
//- (void)articleNavigator:(id)sender didTapImage:(NSString*)sourceURL;

//- (void)articleNavigatorDidTapEdit:(id)sender

//- (void)articleNavigator:(id)sender didTapEditForSection:(NSString*)sectionAnchorFragment;

@end

NS_ASSUME_NONNULL_END
