//
//  WKWebView+SuppressSelection.m
//  Wikipedia
//
//  Created by Adam Baso on 2/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WKWebView+WMFSuppressSelection.h"

@implementation WKWebView (WMF_SuppressSelection)

- (void)wmf_suppressSelection {
    self.userInteractionEnabled = NO;
    self.userInteractionEnabled = YES;
}

@end
