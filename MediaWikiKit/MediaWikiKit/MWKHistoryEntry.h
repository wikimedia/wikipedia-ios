//
//  MWKHistoryList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"
#import "MWKList.h"

@class MWKTitle;

typedef NS_ENUM (NSUInteger, MWKHistoryDiscoveryMethod) {
    /**
     * Title discovered by unknown means.
     */
    MWKHistoryDiscoveryMethodUnknown,

    /**
     * Discovered via a generic search (e.g. wiki, nearby, or related).
     */
    MWKHistoryDiscoveryMethodSearch,

    /**
     * Discovered via the random feature.
     */
    MWKHistoryDiscoveryMethodRandom,

    /**
     * Discovered by tapping a link.
     */
    MWKHistoryDiscoveryMethodLink,

    ///
    /// @name Legacy Discovery Methods
    ///

    /**
     * "Discovered" by navigating back (or forward).
     */
    MWKHistoryDiscoveryMethodBackForward,

    /**
     * "Discovered" by selecting an entry in the saved page list.
     */
    MWKHistoryDiscoveryMethodSaved,

    /**
     * "Discovered" by reloading the latest revision of a title.
     * @warning This method is considered "unknown" when written to disk
     */
    MWKHistoryDiscoveryMethodReloadFromNetwork,

    /**
     * "Discovered" by loading the current version from disk.
     * @warning This method is considered "unknown" when written to disk
     */
    MWKHistoryDiscoveryMethodReloadFromCache,

    MWKHistoryDiscoveryMethod3dTouchPop
};

@interface MWKHistoryEntry : MWKSiteDataObject
    <MWKListObject>

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readwrite, strong, nonatomic) NSDate* date;
@property (readwrite, assign, nonatomic) MWKHistoryDiscoveryMethod discoveryMethod;
@property (readwrite, assign, nonatomic) CGFloat scrollPosition;

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

+ (NSString*)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
+ (MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString*)string;

- (BOOL)discoveryMethodRequiresScrollPositionRestore;

@end
