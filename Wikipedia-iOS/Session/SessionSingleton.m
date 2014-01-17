//  Created by Monte Hurd on 12/6/13.

#import "SessionSingleton.h"

@implementation SessionSingleton

+ (SessionSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(NSString *)searchApiUrl
{
    return [NSString stringWithFormat:@"https://%@.m.%@/w/api.php", [self domain], [self site]];
}

-(void)setDomain:(NSString *)domain
{

//domain = @"test";

    [[NSUserDefaults standardUserDefaults] setObject:domain forKey:@"Domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)domain
{

//return @"test";

    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Domain"];
}

-(void)setDomainName:(NSString *)domainName
{
    [[NSUserDefaults standardUserDefaults] setObject:domainName forKey:@"DomainName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)domainName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"DomainName"];
}

-(void)setSite:(NSString *)site
{
    [[NSUserDefaults standardUserDefaults] setObject:site forKey:@"Site"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString *)site
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"Site"];
}

@end

