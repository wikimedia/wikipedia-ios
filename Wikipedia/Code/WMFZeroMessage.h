//
//  WMFZeroMessage.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface WMFZeroMessage : MTLModel
<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* message;
@property (nonatomic, strong, readonly) UIColor* foreground;
@property (nonatomic, strong, readonly) UIColor* background;

@end
