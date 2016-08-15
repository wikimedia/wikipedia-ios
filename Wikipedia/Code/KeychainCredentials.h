#import <Foundation/Foundation.h>

@interface KeychainCredentials : NSObject

@property (strong, nonatomic) NSString* userName;
@property (strong, nonatomic) NSString* password;

// Edit tokens are stored in the editTokens dictionary with language code
// keys mapping to token string values.
@property (strong, nonatomic) NSMutableDictionary* editTokens;

@end
