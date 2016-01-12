//
//  WMFTextualSaveButton.h
//  Wikipedia
//
//  Created by Brian Gerstle on 1/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  RTL-compliant control which lays out a save button (bookmark icon) and text.
 */
@interface WMFTextualSaveButton : UIControl

@property (nonatomic, weak) IBOutlet UIImageView* saveIconImageView;

@property (nonatomic, weak) IBOutlet UILabel* saveTextLabel;

@end
