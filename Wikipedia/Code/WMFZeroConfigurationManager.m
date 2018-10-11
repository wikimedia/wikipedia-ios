#import "WMFZeroConfigurationManager.h"
#import <WMF/WMFZeroConfiguration.h>
#import <WMF/WMFZeroConfigurationFetcher.h>
#import <WMF/MWKLanguageLinkController.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFZeroRatingChanged = @"WMFZeroDispositionDidChange";
NSString *const WMFZeroOnDialogShownOnce = @"ZeroOnDialogShownOnce";
NSString *const WMFZeroWarnWhenLeaving = @"ZeroWarnWhenLeaving";
NSString *const WMFZeroXCarrier = @"X-Carrier";
NSString *const WMFZeroXCarrierMeta = @"X-Carrier-Meta";

@interface WMFZeroConfigurationManager ()

@property (nonatomic, strong, readonly) WMFZeroConfigurationFetcher *zeroConfigurationFetcher;
@property (nonatomic, strong, nullable, readwrite) WMFZeroConfiguration *zeroConfiguration;

@property (atomic, copy, nullable) NSString *previousPartnerXCarrier;
@property (atomic, copy, nullable) NSString *previousPartnerXCarrierMeta;
@property (atomic, readwrite) BOOL isZeroRated;

@end

@implementation WMFZeroConfigurationManager
@synthesize isZeroRated = _isZeroRated;
@synthesize zeroConfigurationFetcher = _zeroConfigurationFetcher;

+ (void)load {
    [super load];
}

- (WMFZeroConfigurationFetcher *)zeroConfigurationFetcher {
    if (!_zeroConfigurationFetcher) {
        _zeroConfigurationFetcher = [[WMFZeroConfigurationFetcher alloc] init];
    }
    return _zeroConfigurationFetcher;
}

- (void)setIsZeroRated:(BOOL)isZeroRated {
    @synchronized(self) {
        if (_isZeroRated != isZeroRated) {
            _isZeroRated = isZeroRated;
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFZeroRatingChanged object:self];
        }
    }
}

- (BOOL)isZeroRated {
    BOOL isZeroRated;
    @synchronized(self) {
        isZeroRated = _isZeroRated;
    }
    return isZeroRated;
}

- (void)setWarnWhenLeaving:(BOOL)warnWhenLeaving {
    [[NSUserDefaults wmf] setObject:[NSNumber numberWithBool:warnWhenLeaving]
                                          forKey:WMFZeroWarnWhenLeaving];
}

- (BOOL)warnWhenLeaving {
    return [[NSUserDefaults wmf] boolForKey:WMFZeroWarnWhenLeaving];
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
 *   values instead apparently.) So in the nil message case we set isZeroRated "NO".
 */
- (void)fetchZeroConfigurationAndSetIsZeroRatedIfNecessary {

    // Note: don't nil out self.zeroConfiguration in this method
    // because if we do we can't show its exit message strings!

    //TODO: ensure thread safety so we can do this work off the main thread...
    dispatch_async(dispatch_get_main_queue(), ^{
        @weakify(self);
        [self fetchZeroConfigurationWithFailure:^(NSError *_Nonnull error) {
            @strongify(self);
            self.isZeroRated = NO;
        }
            succcess:^(WMFZeroConfiguration *zeroConfiguration) {
                @strongify(self);

                // If the config is not enabled its "message" will be nil, so if we detect a nil message
                // set the isZeroRated to NO before we post the WMFZeroRatingChanged notification.
                if (zeroConfiguration.message == nil) {
                    self.isZeroRated = NO;
                    // Reminder: don't nil out self.zeroConfiguration here or the carrier's exit message won't be available.
                } else {
                    self.zeroConfiguration = zeroConfiguration;
                    self.isZeroRated = YES;
                }
            }];
    });
}

- (void)fetchZeroConfigurationWithFailure:(WMFErrorHandler)failure succcess:(WMFSuccessIdHandler)success {
    [self.zeroConfigurationFetcher cancelAllFetches];
    [self.zeroConfigurationFetcher fetchZeroConfigurationForSiteURL:[[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL] failure:failure success:success];
}

- (void)updateZeroRatingAndZeroConfigurationForResponseHeadersIfNecessary:(NSDictionary *)headers {
    NSAssert(headers != nil, @"Expecting response headers.");
    if (!headers) {
        return;
    }

    BOOL zeroEnabled = self.isZeroRated;

    NSString *xCarrierFromHeader = [headers objectForKey:WMFZeroXCarrier];
    BOOL hasZeroHeader = (xCarrierFromHeader != nil);
    if (hasZeroHeader) {
        NSString *xCarrierMetaFromHeader = [headers objectForKey:WMFZeroXCarrierMeta];
        if ([self hasChangeHappenedToCarrier:xCarrierFromHeader orCarrierMeta:xCarrierMetaFromHeader]) {
            self.previousPartnerXCarrier = xCarrierFromHeader;
            self.previousPartnerXCarrierMeta = xCarrierMetaFromHeader;
            [self fetchZeroConfigurationAndSetIsZeroRatedIfNecessary];
        }
    } else if (zeroEnabled) {
        self.previousPartnerXCarrier = nil;
        self.previousPartnerXCarrierMeta = nil;
        self.isZeroRated = NO;
    }
}

- (BOOL)hasChangeHappenedToCarrier:(NSString *)xCarrier orCarrierMeta:(NSString *)xCarrierMeta {
    return !(
        WMF_IS_EQUAL(self.previousPartnerXCarrier, xCarrier) &&
        WMF_IS_EQUAL(self.previousPartnerXCarrierMeta, xCarrierMeta));
}

@end

NS_ASSUME_NONNULL_END
