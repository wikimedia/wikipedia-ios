//
//  WMFMinimalArticleContentController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFMinimalArticleContentController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <DTCoreText/DTAttributedTextContentView.h>
#import <DTCoreText/DTAttributedTextCell.h>
#import <DTCoreText/DTLinkButton.h>

@interface WMFMinimalArticleContentController ()
<DTAttributedTextContentViewDelegate>
@end

@implementation WMFMinimalArticleContentController

- (void)configureContentView:(DTAttributedTextContentView*)contentView {
    contentView.delegate         = self;
    contentView.shouldDrawImages = NO;
    contentView.shouldDrawLinks  = YES;
}

- (void)configureCell:(DTAttributedTextCell*)attributedTextCell {
    attributedTextCell.textDelegate = self;
    [self configureContentView:attributedTextCell.attributedTextContextView];
}

#pragma mark - DTAttributedTextContentViewDelegate

- (UIView*)attributedTextContentView:(DTAttributedTextContentView*)attributedTextContentView
                         viewForLink:(NSURL*)url
                          identifier:(NSString*)identifier
                               frame:(CGRect)frame {
    DTLinkButton* linkButton = [[DTLinkButton alloc] initWithFrame:frame];
    linkButton.GUID = identifier;
    linkButton.URL  = url;
//    @weakify(attributedTextContentView);
//    @weakify(self);
    [linkButton bk_addEventHandler:^(DTLinkButton* sender) {
//        @strongify(self);
//        @strongify(attributedTextContentView);
//        [self.articleNavigationDelegate articleView:attributedTextContentView didTapLinkToPage:sender.URL];
        DDLogVerbose(@"link tapped: %@", sender.URL);
    } forControlEvents:UIControlEventTouchUpInside];
    return linkButton;
}

@end
