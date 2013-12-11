//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@interface SessionSingleton : NSObject

@property (strong, nonatomic) NSString *site;
@property (strong, nonatomic) NSString *domain;

+ (SessionSingleton *)sharedInstance;

@end
