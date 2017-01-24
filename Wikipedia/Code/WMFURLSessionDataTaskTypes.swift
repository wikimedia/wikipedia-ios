import Foundation

public typealias WMFURLSessionDataTaskSuccessHandler = ((URLSessionDataTask, Any?) -> Void)?
public typealias WMFURLSessionDataTaskFailureHandler = ((URLSessionDataTask?, Error) -> Void)?
