//
//  WMFPicOfTheDayTableViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMFPicOfTheDayTableViewCell : UITableViewCell

- (void)setImageURL:(NSURL*)imageURL;

- (void)setDisplayTitle:(NSString*)displayTitle;

+ (CGFloat)estimatedRowHeight;

@end
