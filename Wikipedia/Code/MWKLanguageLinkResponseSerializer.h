#import <WMF/WMFApiJsonResponseSerializer.h>

/**
 * Converts langlink query responses into the form of `[String:[MWKLanguageLink]]` where the string
 * is a pageID.
 *
 * Keeping the response in the indexed form allows future support of querying multiple titles at once.
 */
@interface MWKLanguageLinkResponseSerializer : WMFApiJsonResponseSerializer

@end
