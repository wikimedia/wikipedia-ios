//  Created by Monte Hurd on 3/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class MWKArticle;

@interface WMFWebViewFooterViewController : UIViewController

- (void)updateReadMoreForArticle:(MWKArticle*)article;

- (void)updateLastModifiedDate:(NSDate*)date userName:(NSString*)userName;
- (void)updateLegalFooterLocalizedText;

@end
