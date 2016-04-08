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

@property (nonatomic, copy, nonnull, readonly) NSString* message;
@property (nonatomic, strong, nonnull, readonly) UIColor* foreground;
@property (nonatomic, strong, nonnull, readonly) UIColor* background;
@property (nonatomic, copy, nullable, readonly) NSString* exitTitle;
@property (nonatomic, copy, nullable, readonly) NSString* exitWarning;
@property (nonatomic, copy, nullable, readonly) NSString* partnerInfoText;
@property (nonatomic, copy, nullable, readonly) NSString* partnerInfoUrl;
@property (nonatomic, copy, nullable, readonly) NSString* bannerUrl;

@end
