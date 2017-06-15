/**
 *   Protocol which intercepts all HTTP requests and prevents them from ever starting.
 *
 *   Useful for reliably testing cancellation, since you're guaranteed to never get a successful or
 *   error response.
 *
 *   @warning: Be sure to unregister this class after your test!
 */
@interface WMFHTTPHangingProtocol : NSURLProtocol

@end
