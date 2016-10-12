#ifndef Wikipedia_Global_h
#define Wikipedia_Global_h
/**
   Global header included in every app and test file (see Wikipedia-Prefix.pch).

   Done as a separate header so it can be reused in unit tests.
 */

#define QUOTE2(x) #x
#define QUOTE(x) QUOTE2(x)

@import WMFUI;

#define URL_PRIVACY_POLICY @"https://m.wikimediafoundation.org/wiki/Privacy_policy"

#endif
