//
//  WMFMostReadTitlesResponse.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/11/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

@class MWKSite;

@interface WMFMostReadTitlesResponseItemArticle : MTLModel
<MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString* titleText;
@property (nonatomic, assign, readonly) NSUInteger rank;
@property (nonatomic, assign, readonly) NSUInteger views;

@end

@interface WMFMostReadTitlesResponseItem : MTLModel
<MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSDate* date;
@property (nonatomic, strong, readonly) NSArray<WMFMostReadTitlesResponseItemArticle*>* articles;
@property (nonatomic, strong, readonly) MWKSite* site;

@end

@interface WMFMostReadTitlesResponse : MTLModel
<MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSArray<WMFMostReadTitlesResponseItem*>* items;

@end
