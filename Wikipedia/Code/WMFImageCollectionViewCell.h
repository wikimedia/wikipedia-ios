//
//  WMFImageCollectionViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SSDataSources/SSBaseCollectionCell.h>

@interface WMFImageCollectionViewCell : SSBaseCollectionCell
@property (strong, nonatomic) IBOutlet UIImageView* imageView;
@end
