#import "WWNMachineThumbnailStore.h"

#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#import "../../WWNCompositorBridge.h"
#endif

@implementation WWNMachineThumbnailStore

+ (NSString *)thumbnailsDirectory {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSURL *base = [[fm URLsForDirectory:NSApplicationSupportDirectory
                            inDomains:NSUserDomainMask] firstObject];
  if (!base) {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"wawona-thumbnails"];
  }
  NSURL *dirURL = [[[base URLByAppendingPathComponent:@"Wawona" isDirectory:YES]
      URLByAppendingPathComponent:@"MachineThumbnails"
                     isDirectory:YES] copy];
  [fm createDirectoryAtURL:dirURL
 withIntermediateDirectories:YES
                  attributes:nil
                       error:nil];
  return dirURL.path;
}

+ (NSString *)safeMachineId:(NSString *)machineId {
  return [[machineId stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
      stringByReplacingOccurrencesOfString:@":" withString:@"_"];
}

+ (NSString *)thumbnailPathForMachineId:(NSString *)machineId {
  if (machineId.length == 0) {
    return nil;
  }
  NSString *file = [[self safeMachineId:machineId] stringByAppendingString:@".png"];
  return [[self thumbnailsDirectory] stringByAppendingPathComponent:file];
}

#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
+ (NSImage *)thumbnailForMachineId:(NSString *)machineId {
  NSString *path = [self thumbnailPathForMachineId:machineId];
  if (path.length == 0) {
    return nil;
  }
  return [[NSImage alloc] initWithContentsOfFile:path];
}

+ (BOOL)saveThumbnailPNGData:(NSData *)pngData forMachineId:(NSString *)machineId {
  if (pngData.length == 0 || machineId.length == 0) {
    return NO;
  }
  NSString *path = [self thumbnailPathForMachineId:machineId];
  if (path.length == 0) {
    return NO;
  }
  return [pngData writeToFile:path atomically:YES];
}

+ (BOOL)saveThumbnailFromWindow:(NSWindow *)window machineId:(NSString *)machineId {
  if (!window || machineId.length == 0) {
    return NO;
  }
  NSView *view = window.contentView;
  if (!view) {
    return NO;
  }
  NSRect bounds = view.bounds;
  if (bounds.size.width < 1 || bounds.size.height < 1) {
    return NO;
  }
  NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:bounds];
  if (!rep) {
    return NO;
  }
  [view cacheDisplayInRect:bounds toBitmapImageRep:rep];
  NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  return [self saveThumbnailPNGData:pngData forMachineId:machineId];
}

+ (BOOL)captureAndSaveThumbnailForMachineId:(NSString *)machineId {
  if (machineId.length == 0) {
    return NO;
  }
  NSData *pngData = [[WWNCompositorBridge sharedBridge] captureCurrentSessionThumbnailPNGData];
  return [self saveThumbnailPNGData:pngData forMachineId:machineId];
}
#endif

+ (void)deleteThumbnailForMachineId:(NSString *)machineId {
  NSString *path = [self thumbnailPathForMachineId:machineId];
  if (path.length == 0) {
    return;
  }
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
