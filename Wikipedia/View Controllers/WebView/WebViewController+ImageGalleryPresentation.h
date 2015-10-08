//
//  WebViewController+ImageGalleryPresentation.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFWebViewController.h"

@interface WMFWebViewController (ImageGalleryPresentation)

- (void)presentGalleryForArticle:(MWKArticle*)article showingImage:(MWKImage*)selectedImage;

@end
