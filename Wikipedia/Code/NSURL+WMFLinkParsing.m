//
//  NSURL+WMFLinkParsing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSURL+WMFLinkParsing.h"
#import "NSString+Extras.h"
#import "NSString+WMFPageUtilities.h"
#import "MWKTitle.h"
#import "NSURL+Extras.h"

@implementation NSURL (WMFLinkParsing)

- (BOOL)wmf_isInternalLink {
    return [self.path wmf_isInternalLink];
}

- (BOOL)wmf_isCitation {
    return [self.fragment wmf_isCitationFragment];
}

- (NSString*)wmf_internalLinkPath {
    return [self.path wmf_internalLinkPath];
}

- (void)wmf_informNavigationDelegate:(id<WMFArticleNavigationDelegate>)delegate
                          withSender:(id<WMFArticleNavigation> __nullable)articleNavigator {
    if ([self wmf_isCitation]) {
        [delegate articleNavigator:articleNavigator didTapCitationLink:self.fragment];
    } else if ([self wmf_isInternalLink]) {
        MWKTitle* title = [[MWKTitle alloc] initWithURL:self];
        [delegate articleNavigator:articleNavigator didTapLinkToPage:title];
    } else {
        [delegate articleNavigator:articleNavigator didTapExternalLink:[self wmf_urlByPrependingSchemeIfSchemeless]];
    }
}

@end
