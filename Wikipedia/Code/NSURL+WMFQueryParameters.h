#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WMFQueryParameters)

/**
 * Gets a value for a given url query key.
 *
 * @param key   The key to check. For example 'somekey' in the url above.
 *
 * @return      Value associated with the passed key parameter. For the url http://www.wikipedia.org?somekey=somevalue using the key 'somekey' would return the value 'somevalue'. Returns nil if no key found.
 **/
- (nullable NSString *)wmf_valueForQueryKey:(NSString *)key;

/**
 * Gets NSURL with value for given url query key added or modified.
 *
 * @param value     The value to add.
 * @param key       If key is present, just modify its associated value. Else add the key / value.
 *
 * @return          URL with added or updated key value pair. For the url http://www.wikipedia.org?somekey=somevalue using the key 'color' and value 'red' would return the http://www.wikipedia.org?somekey=somevalue&color=red However using the existing key 'somekey' and value 'othervalue' would return http://www.wikipedia.org?somekey=othervalue
 **/
- (NSURL *)wmf_urlWithValue:(NSString *)value forQueryKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
