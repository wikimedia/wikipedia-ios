//
//  WMFCrashReportingDefines.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#ifndef Wikipedia_WMFCrashReportingDefines_h
#define Wikipedia_WMFCrashReportingDefines_h

#ifndef WMF_CRASH_REPORTING_ENABLED
    #if DEBUG
        #define WMF_CRASH_REPORTING_ENABLED 1
    #else
        #define WMF_CRASH_REPORTING_ENABLED 0
    #endif
#endif


#endif
