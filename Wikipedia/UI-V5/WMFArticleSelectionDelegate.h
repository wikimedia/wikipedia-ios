//
//  WMFArticleSelectionDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKArticle;

@protocol WMFArticleSelectionDelegate <NSObject>

- (void)didSelectArticle:(MWKArticle*)article sender:(id)sender;

@end
