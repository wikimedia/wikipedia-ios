#import <WMF/WMFMTLModel.h>

@interface MWKDataObject : WMFMTLModel

- (id)dataExport;

- (NSString *)optionalString:(NSString *)key dict:(NSDictionary *)dict;
- (NSString *)requiredString:(NSString *)key dict:(NSDictionary *)dict;
- (NSString *)requiredString:(NSString *)key dict:(NSDictionary *)dict allowEmpty:(BOOL)allowEmpty;

- (NSNumber *)optionalNumber:(NSString *)key dict:(NSDictionary *)dict;
- (NSNumber *)requiredNumber:(NSString *)key dict:(NSDictionary *)dict;
- (NSNumber *)numberWithString:(NSString *)str;

- (NSDate *)optionalDate:(NSString *)key dict:(NSDictionary *)dict;
- (NSDate *)requiredDate:(NSString *)key dict:(NSDictionary *)dict;
- (NSDate *)getDateFromIso8601DateString:(NSString *)string;
- (NSString *)iso8601DateString:(NSDate *)date;

- (NSDictionary *)optionalDictionary:(NSString *)key dict:(NSDictionary *)dict;
- (NSDictionary *)requiredDictionary:(NSString *)key dict:(NSDictionary *)dict;

@end
