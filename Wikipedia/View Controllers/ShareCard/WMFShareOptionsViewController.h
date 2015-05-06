//
//  ShareOptionsViewController.h
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WMFShareOptionsViewControllerDelegate

- (void)didShowSharePreviewForMWKArticle:(MWKArticle*)article withText:(NSString*)text;
- (void)tappedBackgroundToAbandonWithText:(NSString*)text;
- (void)tappedShareCardWithText:(NSString*)text;
- (void)tappedShareTextWithText:(NSString*)text;
- (void)finishShareWithActivityItems:(NSArray*)activityItems text:(NSString*)text;
@end

@interface WMFShareOptionsViewController : UIViewController

@property (nonatomic, readonly) MWKArticle* article;
@property (nonatomic, copy, readonly) NSString* snippet;
@property (nonatomic, copy, readonly) NSString* snippetForTextOnlySharing;
@property (nonatomic, readonly) UIView* backgroundView;
@property (nonatomic, weak, readonly) id<WMFShareOptionsViewControllerDelegate> delegate;

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
- (instancetype)initWithMWKArticle:(MWKArticle*)article
                           snippet:(NSString*)snippet
                    backgroundView:(UIView*)backgroundView
                          delegate:(id)delegate NS_DESIGNATED_INITIALIZER;

@end
