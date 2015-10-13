//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "PullToRefreshViewController.h"

@class MWKSection, MWKArticle;

@protocol WMFWebViewControllerDelegate;

@interface WebViewController : PullToRefreshViewController
    <UIWebViewDelegate,
     UIScrollViewDelegate,
     UIGestureRecognizerDelegate,
     UIAlertViewDelegate>

@property (nonatomic, strong, nullable) MWKArticle* article;

@property (nonatomic, weak) id<WMFWebViewControllerDelegate> delegate;

@property (nonatomic, strong, readonly) UIWebView* webView;

/**
 * Currently-selected text in the webview, if there is any.
 * @return The selection if it's longer than `kMinimumTextSelectionLength`, otherwise an empty string.
 */
@property (nonatomic, strong, readonly) NSString* selectedText;

- (void)scrollToFragment:(NSString*)fragment;

- (void)scrollToSection:(MWKSection*)section;
- (MWKSection*)currentVisibleSection;

- (void)scrollToVerticalOffset:(CGFloat)offset;
- (CGFloat)currentVerticalOffset;

#pragma mark - Header & Footers

/**
 *  An array of view controllers which will be displayed above the receiver's @c UIWebView content from top to bottom.
 */
@property (nonatomic, strong) UIViewController* headerViewController;

@property (nonatomic, strong) NSArray<UIViewController*>* footerViewControllers;

@end


@protocol WMFWebViewControllerDelegate <NSObject>

- (void)webViewController:(WebViewController*)controller didLoadArticle:(MWKArticle*)article;
- (void)webViewController:(WebViewController*)controller didTapEditForSection:(MWKSection*)section;
- (void)webViewController:(WebViewController*)controller didTapOnLinkForTitle:(MWKTitle*)title;
- (void)webViewController:(WebViewController*)controller didSelectText:(NSString*)text;
- (void)webViewController:(WebViewController*)controller didTapShareWithSelectedText:(NSString*)text;

@end

