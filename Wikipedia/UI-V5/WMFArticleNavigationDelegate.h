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

- (void)articleView:(UIView<WMFArticleNavigation>*)sender didTapLinkToPage:(MWKTitle*)title;

- (void)articleView:(UIView<WMFArticleNavigation>*)sender didTapCitationLink:(NSString*)citationFragment;

- (void)articleView:(UIView<WMFArticleNavigation>*)sender didTapSectionLink:(NSString*)sectionAnchorFragment;

- (void)articleView:(UIView<WMFArticleNavigation>*)sender didTapExternalLink:(NSURL*)externalURL;

//- (void)articleView:(id)sender didTapImage:(NSString*)sourceURL;

//- (void)articleViewDidTapEdit:(id)sender

//- (void)articleView:(id)sender didTapEditForSection:(NSString*)sectionAnchorFragment;

@end

NS_ASSUME_NONNULL_END
