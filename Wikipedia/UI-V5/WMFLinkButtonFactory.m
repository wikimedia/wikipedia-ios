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
#import <DTCoreText/DTAttributedTextCell.h>
#import <DTCoreText/DTLinkButton.h>
#import <DTFoundation/DTTiledLayerWithoutFade.h>

@interface DTAttributedTextContentView (WMFOverrideLayerClass)

@end

@implementation DTAttributedTextContentView (WMFOverrideLayerClass)

+ (void)load {
    /*
       Set tiled layers for all attributed text content views. This prevents rendering all attributed text at once, but
       might require unnecessary overrhead for smaller layers.

       If there's a situation where the amount of text to shown is likely to be small most of the time, consider using
       a custom subclass of DTAttributedTextContentView which returns `CALayer` from `layerClass` w/o checking super.
     */
    [DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
}

@end

@implementation WMFLinkButtonFactory

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
