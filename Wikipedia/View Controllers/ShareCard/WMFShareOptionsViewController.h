//
//  ShareOptionsViewController.h
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMFShareFunnel;

NS_ASSUME_NONNULL_BEGIN

@interface WMFShareOptionsViewController : UIViewController

@property (nonatomic, strong, readonly) MWKArticle* article;
@property (nonatomic, copy, readonly) NSString* snippet;
@property (nonatomic, strong, readonly) WMFShareFunnel* funnel;

/**
 * Initialize a new instance with an article and an optional snippet.
 *
 * @param article           The article the snippet is derived from.
 * @param snippet           Optional. The snippet to share, with any necessary processing already applied.
 * @param backgroundView    The background of the share card.
 * @param delegate          The `WMFShareOptionsViewControllerDelegate`.
 *
 * @note Truncating `snippet` is not necessary, as it's done internally by the share view's `UILabel`.
 */
- (instancetype)initWithArticle:(MWKArticle*)article
                        snippet:(nullable NSString*)snippet
                    shareFunnel:(WMFShareFunnel*)funnel NS_DESIGNATED_INITIALIZER;

- (void)presentShareOptionsFromViewController:(UIViewController*)viewController barButtonItem:(UIBarButtonItem*)item;
- (void)presentShareOptionsFromViewController:(UIViewController*)viewController view:(nullable UIView*)view;

@end

NS_ASSUME_NONNULL_END