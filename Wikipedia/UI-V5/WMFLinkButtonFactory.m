//
//  WMFMinimalArticleContentController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFLinkButtonFactory.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <DTCoreText/DTAttributedTextContentView.h>

#import "NSURL+WMFLinkParsing.h"

@implementation WMFLinkButtonFactory

- (UIView*)attributedTextContentView:(DTAttributedTextContentView*)attributedTextContentView
                         viewForLink:(NSURL*)url
                          identifier:(NSString*)identifier
                               frame:(CGRect)frame {
    DTLinkButton* linkButton = [[DTLinkButton alloc] initWithFrame:frame];
    linkButton.GUID = identifier;
    linkButton.URL  = url;
    @weakify(self);
    [linkButton bk_addEventHandler:^(DTLinkButton* sender) {
        @strongify(self);
        // TODO: pass text content view as sender once DTAttributedTextContentView conforms to the protocol
        [sender.URL wmf_informNavigationDelegate:self.articleNavigationDelegate withSender:nil];
    } forControlEvents:UIControlEventTouchUpInside];
    return linkButton;
}

@end
