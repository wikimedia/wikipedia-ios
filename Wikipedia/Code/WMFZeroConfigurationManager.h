#import <Foundation/Foundation.h>

@class WMFZeroConfiguration;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFZeroRatingChanged;
extern NSString *const WMFZeroOnDialogShownOnce;
extern NSString *const WMFZeroWarnWhenLeaving;
extern NSString *const WMFZeroXCarrier;
extern NSString *const WMFZeroXCarrierMeta;

/**
 *  Manages determination of "isZeroRated" state.
 *
 *  Testing notes:
 *
 *  Wikipedia Zero partner data is managed via https://zero.wikimedia.org/wiki/Special:ZeroPortal
 *  Special permission is required to access this portal.
 *
 *  Proper testing requires 3 types of connection be available:
 *
 *  - For simulating connecting on a Zero rated carrier's network with Zero rating *enabled*, the SF office's wifi has
 *  a network called WMF-Tester, which is configured with the enabled "TEST1" profile:
 *  https://zero.wikimedia.org/wiki/Zero:TEST1
 *  For this configuration we want to let the user know there will be no data charges.
 *
 *  - For simulating connecting on a Zero rated carrier's network with Zero rating *disabled*, your testing phone's
 *  non-WIFI IP address may be added to the disabled "310-260" profile:
 *  https://zero.wikimedia.org/wiki/Zero:310-260
 *  For this configuration we want to let the user know there will be data charges.
 *  To do this, turn off WIFI on a testing phone and be connected to your cellular carrier's data network - ie via LTE.
 *  Then in Safari browse to Google and enter the search term "IP Address". Copy the IP address and edit
 *  the https://zero.wikimedia.org/wiki/Zero:310-260 configuration page's "ipsets" key changing the "default"
 *  IP address to your device's. Save this change marking it as a minor edit with the a note saying something
 *  like "Updating testing IP". Now you must wait ~15 minutes for your change to propagate.
 *  To determine if a Zero rated carrier's configuration is presently disabled we must fetch "zeroconfig" data and
 *  check for a nil "message".
 *
 *  - Also have a wifi network other than WMF-Tester so you can test connecting as a user NOT on a Zero rated network.
 *  For this configuration we want to let the user know there will be data charges.
 *
 *  See ABaso or MHurd for more information.
 */

@interface WMFZeroConfigurationManager : NSObject

/**
 * Inspects zero response headers comparing them to last known values to determine if network Zero rating may have changed.
 *
 * If the zero headers have changed, leading us to believe we are going from isZeroRated NO to isZeroRated YES, it also fetches the carrier zeroConfiguration data so it can double-check that the configuration is actually enabled. The zeroConfiguration's "message" will be nil if the configuration is not enabled. Only after the config is determined to be enabled is "isZeroRated" finally set to YES.
 *
 * Changes to "isZeroRated" are broadcast via a WMFZeroRatingChanged notification.
 */
- (void)updateZeroRatingAndZeroConfigurationForResponseHeadersIfNecessary:(NSDictionary *)headers;

/**
 * Contains carrier specific Zero configuration data such as messages, colors, URLs etc...
 * Conditionally fetched and examined to determine whether "isZeroRated" should be set to YES.
 */
@property (nonatomic, strong, nullable, readonly) WMFZeroConfiguration *zeroConfiguration;

/**
 * Whether or not the user is on a Wikipedia-Zero-rated network.
 * Is only set to YES after zeroConfiguration data is fetched.
 */
@property (atomic, readonly) BOOL isZeroRated;

/**
 *  Whether or not the user prefers to see a modal alert before going to a non-zero-rated URL (i.e. off of Wikipedia).
 */
@property (nonatomic) BOOL warnWhenLeaving;

@end

NS_ASSUME_NONNULL_END
