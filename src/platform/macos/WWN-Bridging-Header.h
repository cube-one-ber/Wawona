//
//  WWN-Bridging-Header.h
//  Bridging header for Swift-Objective-C interop
//

#ifndef WWN_Bridging_Header_h
#define WWN_Bridging_Header_h

// Import UniFFI C header for Swift access when available in this build path.
#if __has_include("wwnFFI.h")
#import "wwnFFI.h"
#endif
#import "ui/Machines/WWNMachineProfileStore.h"
#import "ui/Settings/WWNWaypipeRunner.h"
#import "ui/Settings/WWNPreferencesManager.h"
#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#import "ui/Settings/WWNPreferences.h"
#endif

#endif /* WWN_Bridging_Header_h */
