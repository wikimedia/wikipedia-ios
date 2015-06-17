@import Foundation;
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSString.h>

FOUNDATION_EXPORT double PromiseKitVersionNumber;
FOUNDATION_EXPORT const unsigned char PromiseKitVersionString[];

extern NSString * const PMKErrorDomain;

#define PMKFailingPromiseIndexKey @"PMKFailingPromiseIndexKey"
#define PMKURLErrorFailingURLResponseKey @"PMKURLErrorFailingURLResponseKey"
#define PMKURLErrorFailingDataKey @"PMKURLErrorFailingDataKey"
#define PMKURLErrorFailingStringKey @"PMKURLErrorFailingStringKey"
#define PMKJSONErrorJSONObjectKey @"PMKJSONErrorJSONObjectKey"

#define PMKUnexpectedError 1l
#define PMKUnknownError 2l
#define PMKInvalidUsageError 3l
#define PMKAccessDeniedError 4l
#define PMKOperationCancelled 5l
#define PMKNotFoundError 6l
#define PMKJSONError 7l
#define PMKOperationFailed 8l
#define PMKTaskError 9l

#define PMKTaskErrorLaunchPathKey @"PMKTaskErrorLaunchPathKey"
#define PMKTaskErrorArgumentsKey @"PMKTaskErrorArgumentsKey"
#define PMKTaskErrorStandardOutputKey @"PMKTaskErrorStandardOutputKey"
#define PMKTaskErrorStandardErrorKey @"PMKTaskErrorStandardErrorKey"
#define PMKTaskErrorExitStatusKey @"PMKTaskErrorExitStatusKey"
#import <dispatch/object.h>
#import <dispatch/queue.h>
#import <Foundation/NSObject.h>

typedef void (^PMKResolver)(id);

typedef NS_ENUM(NSInteger, PMKCatchPolicy) {
    PMKCatchPolicyAllErrors,
    PMKCatchPolicyAllErrorsExceptCancellation
};



#if defined(PMKEZBake) && defined(SWIFT_CLASS)
  // https://github.com/PromiseKit/EZiOS7/issues/2
  #define PMKPromise AnyPromise
#else

__attribute__((objc_runtime_name("PMKAnyPromise")))
__attribute__((objc_subclassing_restricted))
@interface PMKPromise : NSObject
@property (nonatomic, readonly) BOOL pending;
@property (nonatomic, readonly) BOOL resolved;
@property (nonatomic, readonly) BOOL fulfilled;
@property (nonatomic, readonly) BOOL rejected;
@end

@compatibility_alias AnyPromise PMKPromise;

#endif



/**
 @see AnyPromise.swift
*/
@interface AnyPromise (objc)

/**
 The provided block is executed when its receiver is resolved.

 If you provide a block that takes a parameter, the value of the receiver will be passed as that parameter.

 @param block The block that is executed when the receiver is resolved.

    [NSURLConnection GET:url].then(^(NSData *data){
        // do something with data
    });

 @return A new promise that is resolved with the value returned from the provided block. For example:

    [NSURLConnection GET:url].then(^(NSData *data){
        return data.length;
    }).then(^(NSNumber *number){
        //…
    });

 @warning *Important* The block passed to `then` may take zero, one, two or three arguments, and return an object or return nothing. This flexibility is why the method signature for then is `id`, which means you will not get completion for the block parameter, and must type it yourself. It is safe to type any block syntax here, so to start with try just: `^{}`.

 @warning *Important* If an exception is thrown inside your block, or you return an `NSError` object the next `Promise` will be rejected. See `catch` for documentation on error handling.

 @warning *Important* `then` is always executed on the main queue.

 @see thenOn
 @see thenInBackground
*/
- (AnyPromise *(^)(id))then;


/**
 The provided block is executed on the default queue when the receiver is fulfilled.

 This method is provided as a convenience for `thenOn`.

 @see then
 @see thenOn
*/
- (AnyPromise *(^)(id))thenInBackground;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is fulfilled.

 @see then
 @see thenInBackground
*/
- (AnyPromise *(^)(dispatch_queue_t, id))thenOn;

#ifndef __cplusplus
/**
 The provided block is executed when the receiver is rejected.

 Provide a block of form `^(NSError *){}` or simply `^{}`. The parameter has type `id` to give you the freedom to choose either.

 The provided block always runs on the main queue.
 
 @warning *Note* Cancellation errors are not caught.
 
 @warning *Note* Since catch is a c++ keyword, this method is not availble in Objective-C++ files. Instead use catchWithPolicy.

 @see catchWithPolicy
*/
- (AnyPromise *(^)(id))catch;
#endif

/**
 The provided block is executed when the receiver is rejected with the specified policy.

 @param policy The policy with which to catch. Either for all errors, or all errors *except* cancellation errors.

 @see catch
*/
- (AnyPromise *(^)(PMKCatchPolicy, id))catchWithPolicy;

/**
 The provided block is executed when the receiver is resolved.

 The provided block always runs on the main queue.

 @see finallyOn
*/
- (AnyPromise *(^)(dispatch_block_t))finally;

/**
 The provided block is executed on the dispatch queue of your choice when the receiver is resolved.

 @see finally
 */
- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))finallyOn;

/**
 The value of the asynchronous task this promise represents.

 A promise has `nil` value if the asynchronous task it represents has not
 finished. If the value is `nil` the promise is still `pending`.

 @warning *Note* Our Swift variant’s value property returns nil if the
 promise is rejected where AnyPromise will return the error object. This
 fits with the pattern where AnyPromise is not strictly typed and is more
 dynamic, but you should be aware of the distinction.

 @return If `resolved`, the object that was used to resolve this promise;
 if `pending`, nil.
*/
- (id)value;

/**
 Creates a resolved promise.

 When developing your own promise systems, it is ocassionally useful to be able to return an already resolved promise.

 @param value The value with which to resolve this promise. Passing an `NSError` will cause the promise to be rejected, otherwise the promise will be fulfilled.

 @return A resolved promise.
*/
+ (instancetype)promiseWithValue:(id)value;

/**
 Create a new promise that resolves with the provided block.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains.
 
 If `resolve` is called with an `NSError` object, the promise is
 rejected, otherwise the promise is fulfilled.

 Don’t use this method if you already have promises! Instead, just
 return your promise.

 Should you need to fulfill a promise but have no sensical value to use:
 your promise is a `void` promise: fulfill with `nil`.

 The block you pass is executed immediately on the calling thread.

 @param block The provided block is immediately executed, inside the block
 call `resolve` to resolve this promise and cause any attached handlers to
 execute. If you are wrapping a delegate-based system, we recommend
 instead to use: promiseWithResolver:

 @return A new promise.
 
 @warning *Important* Resolving a promise with `nil` fulfills it.

 @see http://promisekit.org/sealing-your-own-promises/
 @see http://promisekit.org/wrapping-delegation/
*/
+ (instancetype)promiseWithResolverBlock:(void (^)(PMKResolver resolve))resolverBlock;

/**
 Create a new promise with an associated resolver.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains. Generally,
 prefer resolverWithBlock: as the resulting code is more elegant.

    PMKResolver resolve;
    AnyPromise *promise = [AnyPromise promiseWithResolver:&resolve];

    // later
    resolve(@"foo");

 @param resolver A reference to a block pointer of PMKResolver type.
 You can then call your resolver to resolve this promise.

 @return A new promise.

 @warning *Important* The resolver strongly retains the promise.

 @see promiseWithResolverBlock:
*/
- (instancetype)initWithResolver:(PMKResolver __strong *)resolver;

@end



@interface AnyPromise (Unavailable)

- (instancetype)init __attribute__((unavailable("It is illegal to create an unresolvable promise.")));
+ (instancetype)new __attribute__((unavailable("It is illegal to create an unresolvable promise.")));

@end



typedef void (^PMKAdapter)(id, NSError *);
typedef void (^PMKIntegerAdapter)(NSInteger, NSError *);
typedef void (^PMKBooleanAdapter)(BOOL, NSError *);

@interface AnyPromise (Adapters)

/**
 Create a new promise by adapting an existing asynchronous system.

 The pattern of a completion block that passes two parameters, the first
 the result and the second an `NSError` object is so common that we
 provide this convenience adapter to make wrapping such systems more
 elegant.

    return [PMKPromise promiseWithAdapter:^(PMKAdapter adapter){
        PFQuery *query = [PFQuery …];
        [query findObjectsInBackgroundWithBlock:adapter];
    }];

 @warning *Important* If both parameters are nil, the promise fulfills,
 if both are non-nil the promise rejects. This is per the convention.

 @see http://promisekit.org/sealing-your-own-promises/
 */
+ (instancetype)promiseWithAdapterBlock:(void (^)(PMKAdapter adapter))block;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(NSInteger, NSError *)`.
 NSInteger will cast to enums provided the enum has been wrapped with
 `NS_ENUM`. All of Apple’s enums are, so if you find one that hasn’t you
 may need to make a pull-request.

 @see promiseWithAdapter
 */
+ (instancetype)promiseWithIntegerAdapterBlock:(void (^)(PMKIntegerAdapter adapter))block;

/**
 Create a new promise by adapting an existing asynchronous system.

 Adapts asynchronous systems that complete with `^(BOOL, NSError *)`.

 @see promiseWithAdapter
 */
+ (instancetype)promiseWithBooleanAdapterBlock:(void (^)(PMKBooleanAdapter adapter))block;

@end



/**
 Whenever resolving a promise you may resolve with a tuple, eg.
 returning from a `then` or `catch` handler or resolving a new promise.

 Consumers of your Promise are not compelled to consume any arguments and
 in fact will often only consume the first parameter. Thus ensure the
 order of parameters is: from most-important to least-important.

 Currently PromiseKit limits you to THREE parameters to the manifold.
*/
#define PMKManifold(...) __PMKManifold(__VA_ARGS__, 3, 2, 1)
#define __PMKManifold(_1, _2, _3, N, ...) __PMKArrayWithCount(N, _1, _2, _3)
extern id __PMKArrayWithCount(NSUInteger, ...);
@import Foundation.NSPointerArray;

#if TARGET_OS_IPHONE
    #define NSPointerArrayMake(N) ({ \
        NSPointerArray *aa = [NSPointerArray strongObjectsPointerArray]; \
        aa.count = N; \
        aa; \
    })
#else
    static inline NSPointerArray *NSPointerArrayMake(NSUInteger count) {
      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSPointerArray *aa = [[NSPointerArray class] respondsToSelector:@selector(strongObjectsPointerArray)]
            ? [NSPointerArray strongObjectsPointerArray]
            : [NSPointerArray pointerArrayWithStrongObjects];
      #pragma clang diagnostic pop
        aa.count = count;
        return aa;
    }
#endif

#define IsError(o) [o isKindOfClass:[NSError class]]
#define IsPromise(o) [o isKindOfClass:[AnyPromise class]]


@interface AnyPromise (Swift)
- (void)pipe:(void (^)(id))body;
- (AnyPromise *)initWithBridge:(void (^)(PMKResolver))resolver;
+ (void)__consume:(id)obj;
@end

extern NSError *PMKProcessUnhandledException(id thrown);

// TODO really this is not valid, we should instead nest the errors with NSUnderlyingError
// since a special error subclass may be being used and we may not setup it up correctly
// with our copy
#define NSErrorSupplement(_err, supplements) ({ \
    NSError *err = _err; \
    id userInfo = err.userInfo.mutableCopy ?: [NSMutableArray new]; \
    [userInfo addEntriesFromDictionary:supplements]; \
    [[[err class] alloc] initWithDomain:err.domain code:err.code userInfo:userInfo]; \
})
#import <Foundation/NSError.h>

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

@interface NSError (SWIFT_EXTENSION(PromiseKit))
+ (NSError * __nonnull)cancelledError;
+ (void)registerCancelledErrorDomain:(NSString * __nonnull)domain code:(NSInteger)code;
@property (nonatomic, readonly) BOOL cancelled;
@end
/**
 This header provides some compatibility for PromiseKit 1.x’s
 PMKPromise class. It will eventually be deprecated.
*/


typedef void (^PMKFulfiller)(id);
typedef void (^PMKRejecter)(NSError *);

typedef PMKFulfiller PMKPromiseFulfiller;
typedef PMKRejecter PMKPromiseRejecter;

#define PMKUnderlyingExceptionKey NSUnderlyingErrorKey



@interface PMKPromise (BackCompat)

/**
 Create a new promise that is fulfilled or rejected with the provided
 blocks.

 Use this method when wrapping asynchronous code that does *not* use
 promises so that this code can be used in promise chains.

 Don’t use this method if you already have promises! Instead, just
 return your promise.

 Should you need to fulfill a promise but have no sensical value to use;
 your promise is a `void` promise: fulfill with `nil`.

 The block you pass is executed immediately on the calling thread.

 @param block The provided block is immediately executed, any exceptions that occur will be caught and cause the returned promise to be rejected.

  - @param fulfill fulfills the returned promise with the provided value
  - @param reject rejects the returned promise with the provided `NSError`

 @return A new promise.

 @see http://promisekit.org/sealing-your-own-promises/
 @see http://promisekit.org/wrapping-delegation/
*/
+ (instancetype)new:(void(^)(PMKFulfiller fulfill, PMKRejecter reject))block __attribute__((deprecated("Use +promiseWithResolverBlock:")));

/**
 Loops until one or more promises have resolved.

 Because Promises are single-shot, the block to until must return one or more promises. They are then `when`’d. If they succeed the until loop is concluded. If they fail then the @param `catch` handler is executed.

 If the `catch` throws or returns an `NSError` then the loop is ended.

 If the `catch` handler returns a Promise then re-execution of the loop is suspended upon resolution of that Promise. If the Promise succeeds then the loop continues. If it fails the loop ends.

 An example usage is an app starting up that must get data from the Internet before the main ViewController can be shown. You can `until` the poll Promise and in the catch handler decide if the poll should be reattempted or not, perhaps returning a `UIAlertView.promise` allowing the user to choose if they continue or not.
*/
+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler;

@end



@import Foundation.NSDate;

@interface PMKPromise (Deprecated)

+ (PMKPromise *)when:(id)input __attribute__((deprecated("Use PMKWhen()")));
+ (PMKPromise *)pause:(NSTimeInterval)duration __attribute__((deprecated("Use PMKAfter()")));
+ (PMKPromise *)join:(id)input __attribute__((deprecated("Use PMKJoin()")));

- (PMKPromise *( ^ ) ( id ))thenUnleashZalgo __attribute__((unavailable("If you need this, open a ticket, we will provide it, I just want to say hi.")));

+ (PMKPromise *)promiseWithResolver:(PMKResolver)block __attribute__((deprecated("Use +promiseWithResolverBlock:")));
+ (instancetype)promiseWithAdapter:(void (^)(PMKAdapter adapter))block __attribute__((deprecated("Use +promiseWithAdapterBlock:")));
+ (instancetype)promiseWithIntegerAdapter:(void (^)(PMKIntegerAdapter adapter))block __attribute__((deprecated("Use +promiseWithIntegerAdapterBlock:")));
+ (instancetype)promiseWithBooleanAdapter:(void (^)(PMKBooleanAdapter adapter))block __attribute__((deprecated("Use +promiseWithBooleanAdapterBlock:")));

@end



extern void (^PMKUnhandledErrorHandler)(NSError *) __attribute__((unavailable("Use PMKSetUnhandledErrorHandler()")));
#import <dispatch/queue.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSObject.h>



/**
 @return A new promise that resolves after the specified duration.

 @parameter duration The duration in seconds to wait before this promise is resolve.

 For example:

    PMKAfter(1).then(^{
        //…
    });
*/
extern AnyPromise * __nonnull PMKAfter(NSTimeInterval duration);



/**
 `when` is a mechanism for waiting more than one asynchronous task and responding when they are all complete.

 `PMKWhen` accepts varied input. If an array is passed then when those promises fulfill, when’s promise fulfills with an array of fulfillment values. If a dictionary is passed then the same occurs, but when’s promise fulfills with a dictionary of fulfillments keyed as per the input.

 Interestingly, if a single promise is passed then when waits on that single promise, and if a single non-promise object is passed then when fulfills immediately with that object. If the array or dictionary that is passed contains objects that are not promises, then these objects are considered fulfilled promises. The reason we do this is to allow a pattern know as "abstracting away asynchronicity".

 If *any* of the provided promises reject, the returned promise is immediately rejected with that promise’s rejection. The error’s `userInfo` object is supplemented with `PMKFailingPromiseIndexKey`.

 For example:

    PMKWhen(@[promise1, promise2]).then(^(NSArray *results){
        //…
    });

 @warning *Important* In the event of rejection the other promises will continue to resolve and as per any other promise will eithe fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed. In such situations use `PMKJoin`.

 @param input The input upon which to wait before resolving this promise.

 @return A promise that is resolved with either:

  1. An array of values from the provided array of promises.
  2. The value from the provided promise.
  3. The provided non-promise object.

 @see PMKJoin

*/
extern AnyPromise * __nonnull PMKWhen(id __nonnull input);



/**
 Creates a new promise that resolves only when all provided promises have resolved.

 Typically, you should use `PMKWhen`.

 For example:

    PMKJoin(@[promise1, promise2]).then(^(NSArray *results, NSArray *values, NSArray *errors){
        //…
    });

 @warning *Important* This promise is not rejectable. Thus it is up to you to propogate an error if you want any subsequent chain to continue being rejected.

 @param promises An array of promises.

 @return A promise that thens three parameters:

  1) An array of mixed values and errors from the resolved input.
  2) An array of values from the promises that fulfilled.
  3) An array of errors from the promises that rejected or nil if all promises fulfilled.

 @see when
*/
AnyPromise *__nonnull PMKJoin(NSArray * __nonnull promises);



/**
 Literally hangs this thread until the promise has resolved.
 
 Do not use hang… unless you are testing, playing or debugging.
 
 If you use it in production code I will literally and honestly cry like a child.
 
 @return The resolved value of the promise.

 @warning T SAFE. IT IS NOT SAFE. IT IS NOT SAFE. IT IS NOT SAFE. IT IS NO
*/
extern id __nullable PMKHang(AnyPromise * __nonnull promise);



/**
 Sets the unhandled error handler.

 If a promise is rejected and no catch handler is called in its chain, the
 provided handler is called. The default handler logs the error.

    PMKSetUnhandledErrorHandler(^(NSError *error){
        NSLog(@"Unhandled error: %@", error);
    });

 @warning *Important* The handler is executed on an undefined queue.
 
 @warning *Important* Don’t use promises in your handler, or you risk an
 infinite error loop.
 
 @warning *Important* This function is totally not thread-safe and if
 some promise is already executing when you set this the results are
 undefined (though safe if you are programming safely because either
 your handler or the previous handler will be called). So do this at
 application startup and *NOWHERE ELSE!*

 @return The previous unhandled error handler.
*/
extern id __nonnull PMKSetUnhandledErrorHandler(void (^__nonnull handler)(NSError * __nonnull));



/**
 Sets the unhandled exception handler.

 If an exception is thrown inside an AnyPromise handler it is caught and
 this handler is executed to determine if the promise is rejected.
 
 The default handler rejects the promise if an NSError or an NSString is
 thrown.
 
 The default handler in PromiseKit 1.x would reject whatever object was
 thrown (including nil).

 @warning *Important* This handler is provided to allow you to customize
 which exceptions cause rejection and which abort. You should either
 return a fully-formed NSError object or nil. Returning nil causes the
 exception to be re-thrown.

 @warning *Important* The handler is executed on an undefined queue.

 @warning *Important* This function is thread-safe, but to facilitate this
 it can only be called once per application lifetime and it must be called
 before any promise in the app throws an exception. Subsequent calls will
 silently fail.
*/
extern void PMKSetUnhandledExceptionHandler(NSError * __nullable (^__nonnull handler)(id __nullable));



/**
 Executes the provided block on a background queue.

 dispatch_promise is a convenient way to start a promise chain where the
 first step needs to run synchronously on a background queue.

    dispatch_promise(^{
        return md5(input);
    }).then(^(NSString *md5){
        NSLog(@"md5: %@", md5);
    });

 @param block The block to be executed in the background. Returning an `NSError` will reject the promise, everything else (including void) fulfills the promise.

 @return A promise resolved with the return value of the provided block.

 @see dispatch_async
*/
extern AnyPromise * __nonnull dispatch_promise(id __nonnull block);



/**
 Executes the provided block on the specified background queue.

    dispatch_promise_on(myDispatchQueue, ^{
        return md5(input);
    }).then(^(NSString *md5){
        NSLog(@"md5: %@", md5);
    });

 @param block The block to be executed in the background. Returning an `NSError` will reject the promise, everything else (including void) fulfills the promise.

 @return A promise resolved with the return value of the provided block.

 @see dispatch_promise
*/
extern AnyPromise * __nonnull dispatch_promise_on(dispatch_queue_t __nonnull queue, id __nonnull block);



#define PMKJSONDeserializationOptions ((NSJSONReadingOptions)(NSJSONReadingAllowFragments | NSJSONReadingMutableContainers))

#define PMKHTTPURLResponseIsJSON(rsp) [@[@"application/json", @"text/json", @"text/javascript"] containsObject:[rsp MIMEType]]
#define PMKHTTPURLResponseIsImage(rsp) [@[@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap"] containsObject:[rsp MIMEType]]
#define PMKHTTPURLResponseIsText(rsp) [[rsp MIMEType] hasPrefix:@"text/"]



#if defined(__has_include)
  #if __has_include(<PromiseKit/ACAccountStore+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/AVAudioSession+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/CKContainer+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/CKDatabase+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/CLGeocoder+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/CLLocationManager+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/NSNotificationCenter+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/NSTask+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/NSURLConnection+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/MKDirections+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/MKMapSnapshotter+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/CALayer+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/SLRequest+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/SKRequest+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/SCNetworkReachability+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/UIActionSheet+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/UIAlertView+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/UIView+AnyPromise.h>)
  #endif
  #if __has_include(<PromiseKit/UIViewController+AnyPromise.h>)
  #endif
#endif
#import <Foundation/NSMethodSignature.h>

struct PMKBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
    	unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    	void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

typedef NS_OPTIONS(NSUInteger, PMKBlockDescriptionFlags) {
    PMKBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    PMKBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    PMKBlockDescriptionFlagsIsGlobal = (1 << 28),
    PMKBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    PMKBlockDescriptionFlagsHasSignature = (1 << 30)
};

// It appears 10.7 doesn't support quotes in method signatures. Remove them
// via @rabovik's method. See https://github.com/OliverLetterer/SLObjectiveCRuntimeAdditions/pull/2
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
NS_INLINE static const char * pmk_removeQuotesFromMethodSignature(const char *str){
    char *result = malloc(strlen(str) + 1);
    BOOL skip = NO;
    char *to = result;
    char c;
    while ((c = *str++)) {
        if ('"' == c) {
            skip = !skip;
            continue;
        }
        if (skip) continue;
        *to++ = c;
    }
    *to = '\0';
    return result;
}
#endif

static NSMethodSignature *NSMethodSignatureForBlock(id block) {
    if (!block)
        return nil;

    struct PMKBlockLiteral *blockRef = (__bridge struct PMKBlockLiteral *)block;
    PMKBlockDescriptionFlags flags = (PMKBlockDescriptionFlags)blockRef->flags;

    if (flags & PMKBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & PMKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *signature = (*(const char **)signatureLocation);
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
        signature = pmk_removeQuotesFromMethodSignature(signature);
        NSMethodSignature *nsSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        free((void *)signature);

        return nsSignature;
#endif
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return 0;
}
#import <dispatch/once.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <string.h>

#ifndef PMKLog
#define PMKLog NSLog
#endif

@interface PMKArray : NSObject {
@public
    id objs[3];
    NSUInteger count;
} @end

@implementation PMKArray

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    if (count <= idx) {
        // this check is necessary due to lack of checks in `pmk_safely_call_block`
        return nil;
    }
    return objs[idx];
}

@end

id __PMKArrayWithCount(NSUInteger count, ...) {
    PMKArray *this = [PMKArray new];
    this->count = count;
    va_list args;
    va_start(args, count);
    for (NSUInteger x = 0; x < count; ++x)
        this->objs[x] = va_arg(args, id);
    va_end(args);
    return this;
}


static inline id _PMKCallVariadicBlock(id frock, id result) {
    NSCAssert(frock, @"");

    NSMethodSignature *sig = NSMethodSignatureForBlock(frock);
    const NSUInteger nargs = sig.numberOfArguments;
    const char rtype = sig.methodReturnType[0];

    #define call_block_with_rtype(type) ({^type{ \
        switch (nargs) { \
            case 1: \
                return ((type(^)(void))frock)(); \
            case 2: { \
                const id arg = [result class] == [PMKArray class] ? result[0] : result; \
                return ((type(^)(id))frock)(arg); \
            } \
            case 3: { \
                type (^block)(id, id) = frock; \
                return [result class] == [PMKArray class] \
                    ? block(result[0], result[1]) \
                    : block(result, nil); \
            } \
            case 4: { \
                type (^block)(id, id, id) = frock; \
                return [result class] == [PMKArray class] \
                    ? block(result[0], result[1], result[2]) \
                    : block(result, nil, nil); \
            } \
            default: \
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"PromiseKit: The provided block’s argument count is unsupported." userInfo:nil]; \
        }}();})

    switch (rtype) {
        case 'v':
            call_block_with_rtype(void);
            return nil;
        case '@':
            return call_block_with_rtype(id) ?: nil;
        case '*': {
            char *str = call_block_with_rtype(char *);
            return str ? @(str) : nil;
        }
        case 'c': return @(call_block_with_rtype(char));
        case 'i': return @(call_block_with_rtype(int));
        case 's': return @(call_block_with_rtype(short));
        case 'l': return @(call_block_with_rtype(long));
        case 'q': return @(call_block_with_rtype(long long));
        case 'C': return @(call_block_with_rtype(unsigned char));
        case 'I': return @(call_block_with_rtype(unsigned int));
        case 'S': return @(call_block_with_rtype(unsigned short));
        case 'L': return @(call_block_with_rtype(unsigned long));
        case 'Q': return @(call_block_with_rtype(unsigned long long));
        case 'f': return @(call_block_with_rtype(float));
        case 'd': return @(call_block_with_rtype(double));
        case 'B': return @(call_block_with_rtype(_Bool));
        case '^':
            if (strcmp(sig.methodReturnType, "^v") == 0) {
                call_block_with_rtype(void);
                return nil;
            }
            // else fall through!
        default:
            @throw [NSException exceptionWithName:@"PromiseKit" reason:@"PromiseKit: Unsupported method signature." userInfo:nil];
    }
}

static id PMKCallVariadicBlock(id frock, id result) {
    @try {
        return _PMKCallVariadicBlock(frock, result);
    } @catch (id thrown) {
        return PMKProcessUnhandledException(thrown);
    }
}


static dispatch_once_t onceToken;
static NSError *(^PMKUnhandledExceptionHandler)(id);

NSError *PMKProcessUnhandledException(id thrown) {

    dispatch_once(&onceToken, ^{
        PMKUnhandledExceptionHandler = ^id(id reason){
            if ([reason isKindOfClass:[NSError class]])
                return reason;
            if ([reason isKindOfClass:[NSString class]])
                return [NSError errorWithDomain:PMKErrorDomain code:PMKUnexpectedError userInfo:@{NSLocalizedDescriptionKey: reason}];
            return nil;
        };
    });

    id err = PMKUnhandledExceptionHandler(thrown);
    if (!err) @throw thrown;
    return err;
}

void PMKSetUnhandledExceptionHandler(NSError *(^newHandler)(id)) {
    dispatch_once(&onceToken, ^{
        PMKUnhandledExceptionHandler = newHandler;
    });
}
@import Dispatch;
@import Foundation.NSDate;
@import Foundation.NSValue;

AnyPromise *PMKAfter(NSTimeInterval duration) {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
        dispatch_after(time, dispatch_get_global_queue(0, 0), ^{
            resolve(@(duration));
        });
    }];
}
@import Foundation.NSKeyValueCoding;

NSString *const PMKErrorDomain = @"PMKErrorDomain";


@implementation AnyPromise (objc)

- (instancetype)initWithResolver:(PMKResolver __strong *)resolver {
    return [self initWithBridge:^(PMKResolver resolve){
        *resolver = resolve;
    }];
}

+ (instancetype)promiseWithResolverBlock:(void (^)(PMKResolver))resolveBlock {
    return [[self alloc] initWithBridge:resolveBlock];
}

+ (instancetype)promiseWithValue:(id)value {
    return [[self alloc] initWithBridge:^(PMKResolver resolve){
        resolve(value);
    }];
}

static inline AnyPromise *AnyPromiseWhen(AnyPromise *when, void(^then)(id, PMKResolver)) {
    return [[[when class] alloc] initWithBridge:^(PMKResolver resolve){
        [when pipe:^(id obj){
            then(obj, resolve);
        }];
    }];
}

static inline AnyPromise *__then(AnyPromise *self, dispatch_queue_t queue, id block) {
    return AnyPromiseWhen(self, ^(id obj, PMKResolver resolve) {
        if (IsError(obj)) {
            resolve(obj);
        } else dispatch_async(queue, ^{
            resolve(PMKCallVariadicBlock(block, obj));
        });
    });
}

- (AnyPromise *(^)(id))then {
    return ^(id block) {
        return __then(self, dispatch_get_main_queue(), block);
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))thenOn {
    return ^(dispatch_queue_t queue, id block) {
        return __then(self, queue, block);
    };
}

- (AnyPromise *(^)(id))thenInBackground {
    return ^(id block) {
        return __then(self, dispatch_get_global_queue(0, 0), block);
    };
}

static inline AnyPromise *__catch(AnyPromise *self, BOOL includeCancellation, id block) {
    return AnyPromiseWhen(self, ^(id obj, PMKResolver resolve) {
        if (IsError(obj) && (includeCancellation || ![obj cancelled])) {
            [[self class] __consume:obj];
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(PMKCallVariadicBlock(block, obj));
            });
        } else {
            resolve(obj);
        }
    });
}

- (AnyPromise *(^)(id))catch {
    return ^(id block) {
        return __catch(self, NO, block);
    };
}

- (AnyPromise *(^)(PMKCatchPolicy, id))catchWithPolicy {
    return ^(PMKCatchPolicy policy, id block) {
        return __catch(self, policy == PMKCatchPolicyAllErrors, block);
    };
}

static inline AnyPromise *__finally(AnyPromise *self, dispatch_queue_t queue, dispatch_block_t block) {
    return AnyPromiseWhen(self, ^(id obj, PMKResolver resolve) {
        dispatch_async(queue, ^{
            block();
            resolve(obj);
        });
    });
}

- (AnyPromise *(^)(dispatch_block_t))finally {
    return ^(dispatch_block_t block) {
        return __finally(self, dispatch_get_main_queue(), block);
    };
}

- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))finallyOn {
    return ^(dispatch_queue_t queue, dispatch_block_t block) {
        return __finally(self, queue, block);
    };
}

- (id)value {
    id result = [self valueForKey:@"__value"];
    return [result isKindOfClass:[PMKArray class]]
        ? result[0]
        : result;
}

@end



@implementation AnyPromise (Adapters)

+ (instancetype)promiseWithAdapterBlock:(void (^)(PMKAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(id value, id error){
            resolve(error ?: value);
        });
    }];
}

+ (instancetype)promiseWithIntegerAdapterBlock:(void (^)(PMKIntegerAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(NSInteger value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

+ (instancetype)promiseWithBooleanAdapterBlock:(void (^)(PMKBooleanAdapter adapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(BOOL value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

@end



@interface AnyPromise (XP)
+ (id)setUnhandledErrorHandler:(id)handler;
@end

id PMKSetUnhandledErrorHandler(void (^handler)(NSError *)) {
    return [AnyPromise setUnhandledErrorHandler:handler];
}
@import Dispatch;

AnyPromise *dispatch_promise(id block) {
    return dispatch_promise_on(dispatch_get_global_queue(0, 0), block);
}

AnyPromise *dispatch_promise_on(dispatch_queue_t queue, id block) {
    return [AnyPromise promiseWithValue:nil].thenOn(queue, block);
}
@import CoreFoundation.CFRunLoop;

id PMKHang(AnyPromise *promise) {
    if (promise.pending) {
        static CFRunLoopSourceContext context;

        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFRunLoopSourceRef runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
        CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);

        promise.finally(^{
            CFRunLoopStop(runLoop);
        });
        while (promise.pending) {
            CFRunLoopRun();
        }
        CFRunLoopRemoveSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
        CFRelease(runLoopSource);
    }

    return promise.value;
}
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSNull;

@implementation AnyPromise (join)

AnyPromise *PMKJoin(NSArray *promises) {
    if (promises == nil)
        return [AnyPromise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"PMKJoin(nil)"}]];

    if (promises.count == 0)
        return [AnyPromise promiseWithValue:PMKManifold(promises, promises)];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSPointerArray *results = NSPointerArrayMake(promises.count);

        __block NSUInteger x = 0;

        [promises enumerateObjectsUsingBlock:^(AnyPromise *promise, NSUInteger ii, BOOL *stop) {
            [promise pipe:^(id value) {
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(value ?: [NSNull null])];
                if (++x == promises.count) {
                    id apples = results.allObjects;
                    id values = [NSMutableArray new];
                    id errors = [NSMutableArray new];
                    for (id apple in apples)
                        [IsError(apple) ? errors : values addObject:apple];
                    if ([errors count] == 0)
                        errors = nil;
                    resolve(PMKManifold(apples, values, errors));
                }
            }];
        }];
    }];
}

@end
@import Foundation.NSDictionary;

#ifndef PMKLog
#define PMKLog NSLog
#endif


@implementation PMKPromise (BackCompat)

+ (instancetype)new:(void(^)(PMKFulfiller, PMKRejecter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        id rejecter = ^(id error){
            if (error == nil) {
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:nil];
            } else if (IsPromise(error)) {
                error = ((PMKPromise *)error).value;
            }
            if (!IsError(error)) {
                id userInfo = @{
                    NSLocalizedDescriptionKey: [error description],
                    NSUnderlyingErrorKey: error
                };
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:userInfo];
            }
            resolve(error);
        };

        id fulfiller = ^(id result){
            if (IsError(result))
                PMKLog(@"PromiseKit: Warning: PMKFulfiller called with NSError.");
            resolve(result);
        };

        @try {
            block(fulfiller, rejecter);
        } @catch (id thrown) {
            resolve(PMKProcessUnhandledException(thrown));
        }
    }];
}

+ (instancetype)until:(id (^)(void))blockReturningPromises catch:(id)failHandler {

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-retain-cycles"

    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        __block void (^block)() = ^{
            AnyPromise *next = PMKWhen(blockReturningPromises());
            next.then(^(id o){
                resolve(o);
                block = nil;
            });
            next.catch(^(NSError *error){
                [AnyPromise promiseWithValue:error].catch(failHandler).then(block).catch(^{
                    resolve(error);
                    block = nil;
                });
            });
        };
        block();
    }];

    #pragma clang diagnostic pop
}

@end



@implementation PMKPromise (Deprecated)

+ (instancetype)when:(id)input {
    return PMKWhen(input);
}

+ (instancetype)pause:(NSTimeInterval)duration {
    return PMKAfter(duration);
}

+ (instancetype)join:(id)input {
    return PMKJoin(input).then(^(id a, id b, id c){
        // preserving PMK 1.x behavior
        return PMKManifold(b, c);
    });
}

+ (instancetype)promiseWithResolver:(PMKResolver)block {
    return [self promiseWithResolverBlock:block];
}

+ (instancetype)promiseWithAdapter:(void (^)(PMKAdapter adapter))block {
    return [self promiseWithAdapterBlock:block];
}

+ (instancetype)promiseWithIntegerAdapter:(void (^)(PMKIntegerAdapter adapter))block {
    return [self promiseWithIntegerAdapterBlock:block];
}

+ (instancetype)promiseWithBooleanAdapter:(void (^)(PMKBooleanAdapter adapter))block {
    return [self promiseWithBooleanAdapterBlock:block];
}

@end
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSProgress;
@import Foundation.NSNull;

// NSProgress resources:
//  * https://robots.thoughtbot.com/asynchronous-nsprogress
//  * http://oleb.net/blog/2014/03/nsprogress/
// NSProgress! Beware!
//  * https://github.com/AFNetworking/AFNetworking/issues/2261


AnyPromise *PMKWhen(id promises) {
    if (promises == nil)
        return [AnyPromise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"PMKWhen(nil)"}]];

    if ([promises isKindOfClass:[NSArray class]] || [promises isKindOfClass:[NSDictionary class]]) {
        if ([promises count] == 0)
            return [AnyPromise promiseWithValue:promises];
    } else if ([promises isKindOfClass:[AnyPromise class]]) {
        promises = @[promises];
    } else {
        return [AnyPromise promiseWithValue:promises];
    }

#ifndef PMKDisableProgress
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:[promises count]];
    progress.pausable = NO;
    progress.cancellable = NO;
#endif

    PMKResolver resolve;
    AnyPromise *rootPromise = [[AnyPromise alloc] initWithResolver:&resolve];
    __block void (^fulfill)();

    __block NSInteger countdown = [promises count];
    void (^yield)(id, id, void(^)(id)) = ^(AnyPromise *promise, id key, void(^set)(id)) {
        if (![promise isKindOfClass:[AnyPromise class]])
            promise = [AnyPromise promiseWithValue:promise];
        [promise pipe:^(id value){
            if (!rootPromise.pending) {
                // suppress “already resolved” log message
            } else if (IsError(value)) {
              #ifndef PMKDisableProgress
                progress.completedUnitCount = progress.totalUnitCount;
              #endif
                resolve(NSErrorSupplement(value, @{PMKFailingPromiseIndexKey: key}));
            } else {
              #ifndef PMKDisableProgress
                progress.completedUnitCount++;
              #endif
                set(promise.value);  // we use -value to unwrap PMKManifolds
                if (--countdown == 0)
                    fulfill();
            }
        }];
    };

    if ([promises isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *results = [NSMutableDictionary new];
        fulfill = ^{ resolve(results); };

        for (id key in promises) {
            yield(promises[key], key, ^(id value){
                results[key] = value;
            });
        }
    } else {
        NSPointerArray *results = NSPointerArrayMake([promises count]);
        fulfill = ^{ resolve(results.allObjects); };

        [promises enumerateObjectsUsingBlock:^(id promise, NSUInteger ii, BOOL *stop) {
            yield(promise, @(ii), ^(id value){
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(value ?: [NSNull null])];
            });
        }];
    }
    
    return rootPromise;
}
