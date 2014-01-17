//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@interface SessionSingleton : NSObject

// These 3 persist across app restarts.
@property (strong, nonatomic) NSString *site;
@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *domainName;

@property (strong, nonatomic, readonly) NSString *searchApiUrl;

+ (SessionSingleton *)sharedInstance;

@end
