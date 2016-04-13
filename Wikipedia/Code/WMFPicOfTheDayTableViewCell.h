//
//  WMFPicOfTheDayTableViewCell.h
//  Wikipedia
//
//  Created by Brian Gerstle on 11/23/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMFPicOfTheDayTableViewCell : UITableViewCell

/**
 *  Do not use this to set the image url, this is only exposed
 * for animations
 */
@property (nonatomic, strong) IBOutlet UIImageView* potdImageView;

- (void)setImageURL:(NSURL*)imageURL;

- (void)setDisplayTitle:(NSString*)displayTitle;

+ (CGFloat)estimatedRowHeight;

@end
