//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

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

@property (nonatomic, strong, nullable, readonly) UIWebView* webView;

@property (nonatomic) BOOL isPeeking;

/**
 * Currently-selected text in the webview, if there is any.
 * @return The selection if it's longer than `kMinimumTextSelectionLength`, otherwise an empty string.
 */
@property (nonatomic, strong, nonnull, readonly) NSString* selectedText;

/**
 *  Animates the scroll view to the given fragment in the browser view.
 *
 *  @param fragment The fragment to scroll to.
 *
 *  @see scrollToFragment:animated:
 */
- (void)scrollToFragment:(NSString*)fragment;

/**
 *  Scroll to the given fragment in the browser view.
 *
 *  @param fragment The fragment to scroll to.
 *  @param animated Whether or not to animate
 */
- (void)scrollToFragment:(NSString*)fragment animated:(BOOL)animated;

/**
 *  Scroll to the @c anchor of the given section.
 *
 *  @param section  The section to scroll to.
 *  @param animated Whether or not to animate.
 *
 *  @see scrollToFragment:animated:
 */
- (void)scrollToSection:(MWKSection*)section animated:(BOOL)animated;

- (nullable MWKSection*)currentVisibleSection;

- (void)scrollToVerticalOffset:(CGFloat)offset;
- (CGFloat)currentVerticalOffset;

- (JSValue*)htmlElementAtLocation:(CGPoint)location;
- (NSURL*)urlForHTMLElement:(JSValue*)element;
- (CGRect)rectForHTMLElement:(JSValue*)element;

/**
 *  Check if web content is visible.
 *
 *  Queries the internal browser view to see if it's within its scroll view's content frame.
 *
 *  @warning This is only intended to be used for workarounds related to internal browser view behavior, only use
 *           if no other options are available.
 *
 *  @return Whether or not the receiver's internal browser view is visible.
 */
@property (nonatomic, assign, readonly) BOOL isWebContentVisible;

#pragma mark - Header & Footers

@property (nonatomic, strong, nullable) UIViewController* headerViewController;

/**
 *  An array of view controllers which will be displayed above the receiver's @c UIWebView content from top to bottom.
 */
@property (nonatomic, strong, nullable) NSArray<UIViewController*>* footerViewControllers;

- (void)scrollToFooterAtIndex:(NSUInteger)index;

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
