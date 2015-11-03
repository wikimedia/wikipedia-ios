//
//  WMFSearchCollectionViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WMFSaveableTitleCollectionViewCell.h"

@interface WMFArticleListCell : WMFSaveableTitleCollectionViewCell

- (void)setTitle:(MWKTitle*)title highlightingSubstring:(NSString*)substring;

- (void)setSearchResultDescription:(NSString*)searchResultDescription;

@end
