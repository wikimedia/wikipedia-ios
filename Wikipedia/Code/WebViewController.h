//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
@import WebKit;

@class MWKSection, MWKArticle, MWKTitle, JSValue;

@protocol WMFWebViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController
    <UIWebViewDelegate,
     UIScrollViewDelegate,
     UIGestureRecognizerDelegate,
     UIAlertViewDelegate>

@property (nonatomic, strong, nullable) MWKArticle* article;

@property (nonatomic, weak, nullable) id<WMFWebViewControllerDelegate> delegate;

@property (nonatomic, strong, nullable, readonly) WKWebView* webView;

@property (nonatomic) BOOL isPeeking;
@property (strong, nonatomic) NSString* peekURLString;

@property (nonatomic) UIEdgeInsets contentInsets;

/**
 *  Scroll to the @c anchor of the given section.
 *
 *  @param section  The section to scroll to.
 *  @param animated Whether or not to animate.
 *
 *  @see scrollToFragment:animated:
 */
- (void)scrollToSection:(MWKSection*)section animated:(BOOL)animated;

- (void)accessibilityCursorToSection:(MWKSection*)section;

- (void)getCurrentVisibleSectionCompletion:(void (^)(MWKSection* _Nullable, NSError* __nullable error))completion;

- (void)scrollToVerticalOffset:(CGFloat)offset;
- (CGFloat)currentVerticalOffset;

- (void)setFontSizeMultiplier:(NSNumber*)fontSize;

#pragma mark - Header & Footers

@property (nonatomic, strong, nullable) UIView* headerView;

/**
 *  An array of view controllers which will be displayed above the receiver's @c UIWebView content from top to bottom.
 *
 *  Setting this property with an array containing the same view controllers in the same order has no effect.
 */
@property (nonatomic, strong, nullable) NSArray<UIViewController*>* footerViewControllers;

- (UIView*)footerAtIndex:(NSUInteger)index;
- (void)scrollToFooterAtIndex:(NSUInteger)index;
- (void)accessibilityCursorToFooterAtIndex:(NSUInteger)index;

- (NSInteger)visibleFooterIndex;

@end


@protocol WMFWebViewControllerDelegate <NSObject>

- (nullable NSString*)webViewController:(WebViewController*)controller titleForFooterViewController:(UIViewController*)footerViewController;

- (void)webViewController:(WebViewController*)controller didLoadArticle:(MWKArticle*)article;
- (void)webViewController:(WebViewController*)controller didTapEditForSection:(MWKSection*)section;
- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title;
- (void)webViewController:(WebViewController*)controller didSelectText:(NSString*)text;
- (void)webViewController:(WebViewController*)controller didTapShareWithSelectedText:(NSString*)text;
- (void)webViewController:(WebViewController*)controller didTapImageWithSourceURLString:(NSString*)imageSourceURLString;

@end

NS_ASSUME_NONNULL_END
