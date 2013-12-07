//  Created by Monte Hurd on 12/6/13.

#import <Foundation/Foundation.h>

@class Site, Domain;
@interface SessionSingleton : NSObject

@property (strong, nonatomic) Site *site;
@property (strong, nonatomic) Domain *domain;

+ (SessionSingleton *)sharedInstance;

@end
