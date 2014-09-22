//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>


// Enums for the FetchFinishedDelegate protocol method.
typedef NS_ENUM(NSInteger, FetchFinalStatus) {
    FETCH_FINAL_STATUS_SUCCEEDED,
    FETCH_FINAL_STATUS_CANCELLED,
    FETCH_FINAL_STATUS_FAILED
};


// Protocol for notifying fetchFinishedDelegate that download has completed.
@protocol FetchFinishedDelegate <NSObject>

- (void)fetchFinished: (id)sender
             userData: (id)userData
               status: (FetchFinalStatus)status
                error: (NSError *)error;

@end


@interface FetcherBase : NSObject


// Object to receive "fetchFinished:" notifications.
@property (nonatomic, weak) id <FetchFinishedDelegate> fetchFinishedDelegate;



// Method for sub-classes of FetcherBase to call to cause the fetchFinishedDelegate
// to be notified via "fetchFinished:" that the fetch is finished.

// Note: FetchFinalStatus is not explicitly passed to this method - it determines
// the status base on introspection of error.
- (void)finishWithError: (NSError *)error
               userData: (id)userData;



// For some fetchers we need raw NSData responses. (Their managers will
// have their responseSerializers overridden with "[AFHTTPResponseSerializer serializer]".)
// This is a quick way to check if the raw data response is potentially valid / contains
// anything useful.
-(BOOL)isDataResponseValid:(id)responseObject;

@end
