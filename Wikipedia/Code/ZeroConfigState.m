#import "ZeroConfigState.h"
//#import <Tweaks/FBTweakInline.h>

#import "WMFZeroConfiguration.h"
#import "WMFZeroConfigurationFetcher.h"
#import "MWKLanguageLinkController.h"
#import <WMFModel/WMFModel-Swift.h>
#import "WMFURLCacheStrings.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFZeroDispositionDidChange = @"WMFZeroDispositionDidChange";

NSString *const ZeroOnDialogShownOnce = @"ZeroOnDialogShownOnce";
NSString *const ZeroWarnWhenLeaving = @"ZeroWarnWhenLeaving";

@interface ZeroConfigState ()

@property (nonatomic, strong, readonly) WMFZeroConfigurationFetcher *zeroConfigurationFetcher;
@property (nonatomic, strong, nullable, readwrite) WMFZeroConfiguration *zeroConfiguration;

@property (atomic, copy, nullable) NSString* previousPartnerXCarrier;
@property (atomic, copy, nullable) NSString* previousPartnerXCarrierMeta;
@property (atomic, readwrite) BOOL disposition;

@end

@implementation ZeroConfigState
@synthesize disposition = _disposition;
@synthesize zeroConfigurationFetcher = _zeroConfigurationFetcher;

+ (void)load {
    [super load];
    //    FBTweakAction(@"Networking", @"Wikipedia Zero", @"Reset ZeroOnDialogShownOnce", ^{
    //        [[NSUserDefaults wmf_userDefaults] setBool:NO forKey:ZeroOnDialogShownOnce];
    //        [[NSUserDefaults wmf_userDefaults] synchronize];
    //    });
}

- (WMFZeroConfigurationFetcher *)zeroConfigurationFetcher {
    if (!_zeroConfigurationFetcher) {
        _zeroConfigurationFetcher = [[WMFZeroConfigurationFetcher alloc] init];
    }
    return _zeroConfigurationFetcher;
}

- (void)setDisposition:(BOOL)disposition {
    @synchronized(self) {
        if(_disposition != disposition){
            _disposition = disposition;
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFZeroDispositionDidChange object:self];
        }
    }
}

- (BOOL)disposition {
    BOOL disposition;
    @synchronized(self) {
        disposition = _disposition;
    }
    return disposition;
}

- (void)setWarnWhenLeaving:(BOOL)warnWhenLeaving {
    [[NSUserDefaults wmf_userDefaults] setObject:[NSNumber numberWithBool:warnWhenLeaving]
                                          forKey:ZeroWarnWhenLeaving];
    [[NSUserDefaults wmf_userDefaults] synchronize];
}

- (BOOL)warnWhenLeaving {
    return [[NSUserDefaults wmf_userDefaults] boolForKey:ZeroWarnWhenLeaving];
}

#pragma mark - Banner Updates

/**
 *   This method:
 *
 * - Fetches carrier specific strings placing them in self.zeroConfiguration object.
 *
 * - If the fetched zeroConfiguration has a nil "message" string, this means even though
 *   there was a header, leading us to believe this network was Zero rated, its Zero
 *   rating is not presently enabled. (It would be nice if the query fetching the
 *   zeroConfiguration returned an "enabled" key/value, but it doesn't - it nils out the
 *   values instead apparently.) So in the nil message case we set disposition "NO".
 */
- (void)fetchZeroConfigurationAndSetDispositionIfNecessary {
    
    // Note: don't nil out self.zeroConfiguration in this method
    // because if we do we can't show its exit message strings!

    //TODO: ensure thread safety so we can do this work off the main thread...
    dispatch_async(dispatch_get_main_queue(), ^{
        @weakify(self);
        AnyPromise *promise = [AnyPromise promiseWithValue:nil];
        promise = [self fetchZeroConfiguration].then(^(WMFZeroConfiguration *zeroConfiguration) {
            @strongify(self);
            
            // If the config is not enabled its "message" will be nil, so if we detect a nil message
            // set the disposition to NO before we post the WMFZeroDispositionDidChange notification.
            if(zeroConfiguration.message == nil){
                self.disposition = NO;
                // Reminder: don't nil out self.zeroConfiguration here or the carrier's exit message won't be available.
            }else{
                self.zeroConfiguration = zeroConfiguration;
                self.disposition = YES;
            }
            
        }).catch(^(NSError* error){
            @strongify(self);
            self.disposition = NO;
        });
    });
}

- (AnyPromise *)fetchZeroConfiguration {
    [self.zeroConfigurationFetcher cancelAllFetches];
    return [self.zeroConfigurationFetcher fetchZeroConfigurationForSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL]];
}

- (void)inspectResponseForZeroHeaders:(NSURLResponse*)response {
    NSHTTPURLResponse* httpUrlResponse = (NSHTTPURLResponse*)response;
    NSDictionary* headers              = httpUrlResponse.allHeaderFields;
    
    bool zeroEnabled = self.disposition;
    
    NSString* xCarrierFromHeader = [headers objectForKey:WMFURLCacheXCarrier];
    bool hasZeroHeader = (xCarrierFromHeader != nil);
    if (hasZeroHeader) {
        NSString* xCarrierMetaFromHeader = [headers objectForKey:WMFURLCacheXCarrierMeta];
        if ([self hasChangeHappenedToCarrier:xCarrierFromHeader orCarrierMeta:xCarrierMetaFromHeader]) {
            self.previousPartnerXCarrier = xCarrierFromHeader;
            self.previousPartnerXCarrierMeta = xCarrierMetaFromHeader;
            [self fetchZeroConfigurationAndSetDispositionIfNecessary];
        }
    }else if(zeroEnabled) {
        self.previousPartnerXCarrier = nil;
        self.previousPartnerXCarrierMeta = nil;
        self.disposition = NO;
    }
}

- (BOOL)hasChangeHappenedToCarrier:(NSString*)xCarrier orCarrierMeta:(NSString*)xCarrierMeta {
    return !(
             [self isNullableString:self.previousPartnerXCarrier equalToNullableString:xCarrier]
             &&
             [self isNullableString:self.previousPartnerXCarrierMeta equalToNullableString:xCarrierMeta]
             );
}

- (BOOL)isNullableString:(nullable NSString*)stringOne equalToNullableString:(nullable NSString*)stringTwo {
    if(stringOne == nil && stringTwo == nil){
        return YES;
    }else if(stringOne != nil && stringTwo == nil){
        return NO;
    }else if(stringOne == nil && stringTwo != nil){
        return NO;
    }else{
        return [stringOne isEqualToString:stringTwo];
    }
}

@end

NS_ASSUME_NONNULL_END
