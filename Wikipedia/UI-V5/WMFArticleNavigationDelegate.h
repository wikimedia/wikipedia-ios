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

- (void)articleNavigator:(id<WMFArticleNavigation>)sender didTapLinkToPage:(MWKTitle*)pageTitle;

- (void)articleNavigator:(id<WMFArticleNavigation>)sender
      didTapCitationLink:(NSString*)citationFragment
                  onPage:(MWKTitle*)pageTitle;

- (void)articleNavigator:(id<WMFArticleNavigation>)sender didTapExternalLink:(NSURL*)externalURL;

//- (void)articleNavigator:(id)sender didTapImage:(NSString*)sourceURL;

//- (void)articleNavigatorDidTapEdit:(id)sender

//- (void)articleNavigator:(id)sender didTapEditForSection:(NSString*)sectionAnchorFragment;

@end

NS_ASSUME_NONNULL_END
