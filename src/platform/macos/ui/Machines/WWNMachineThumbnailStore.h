#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface WWNMachineThumbnailStore : NSObject

+ (nullable NSString *)thumbnailPathForMachineId:(NSString *)machineId;

#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
+ (nullable NSImage *)thumbnailForMachineId:(NSString *)machineId;
+ (BOOL)saveThumbnailPNGData:(NSData *)pngData forMachineId:(NSString *)machineId;
+ (BOOL)saveThumbnailFromWindow:(NSWindow *)window machineId:(NSString *)machineId;
+ (BOOL)captureAndSaveThumbnailForMachineId:(NSString *)machineId;
#endif

+ (void)deleteThumbnailForMachineId:(NSString *)machineId;

@end

NS_ASSUME_NONNULL_END
