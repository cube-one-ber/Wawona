#import "WWNMachinesCoordinator.h"
#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
#import "../Settings/WWNPreferences.h"
#endif
#import <objc/message.h>

@interface WWNMachinesCoordinator ()
#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
@property(nonatomic, strong) NSWindowController *macMachinesController;
#endif
@end

@implementation WWNMachinesCoordinator

+ (instancetype)sharedCoordinator {
  static WWNMachinesCoordinator *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] init];
  });
  return shared;
}

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
- (UIViewController *)buildSwiftUIMachinesController:(dispatch_block_t)onConnect {
  NSArray<NSString *> *candidateNames = @[
    @"WWNMachinesHostingBridge",
    @"Wawona.WWNMachinesHostingBridge",
    @"Wawona_iOS.WWNMachinesHostingBridge",
    @"Wawona_macOS.WWNMachinesHostingBridge",
  ];
  Class bridgeClass = Nil;
  for (NSString *name in candidateNames) {
    bridgeClass = NSClassFromString(name);
    if (bridgeClass) {
      break;
    }
  }
  SEL selector = NSSelectorFromString(@"buildIOSMachinesControllerWithOnConnect:");
  if (!bridgeClass || ![bridgeClass respondsToSelector:selector]) {
    return nil;
  }
  UIViewController *(*buildFn)(id, SEL, dispatch_block_t) =
      (UIViewController *(*)(id, SEL, dispatch_block_t))objc_msgSend;
  return buildFn(bridgeClass, selector, onConnect);
}
#else
- (NSWindowController *)buildSwiftUIMachinesWindowController:(dispatch_block_t)onConnect {
  NSArray<NSString *> *candidateNames = @[
    @"WWNMachinesHostingBridge",
    @"Wawona.WWNMachinesHostingBridge",
    @"Wawona_iOS.WWNMachinesHostingBridge",
    @"Wawona_macOS.WWNMachinesHostingBridge",
  ];
  Class bridgeClass = Nil;
  for (NSString *name in candidateNames) {
    bridgeClass = NSClassFromString(name);
    if (bridgeClass) {
      break;
    }
  }
  SEL selector = NSSelectorFromString(@"buildMacMachinesWindowControllerWithOnConnect:");
  if (!bridgeClass || ![bridgeClass respondsToSelector:selector]) {
    return nil;
  }
  NSWindowController *(*buildFn)(id, SEL, dispatch_block_t) =
      (NSWindowController *(*)(id, SEL, dispatch_block_t))objc_msgSend;
  return buildFn(bridgeClass, selector, onConnect);
}
#endif

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
- (void)presentMachinesFromViewController:(UIViewController *)presenter
                                onConnect:(dispatch_block_t)onConnect {
  UIViewController *top = presenter;
  while (top.presentedViewController != nil) {
    top = top.presentedViewController;
  }
  UIViewController *machinesVC = [self buildSwiftUIMachinesController:onConnect];
  if (!machinesVC) {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Machines UI Unavailable"
                         message:@"SwiftUI machines view failed to load. Regenerate the Xcode project and rebuild."
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [top presentViewController:alert animated:YES completion:nil];
    return;
  }
  [top presentViewController:machinesVC animated:YES completion:nil];
}
#else
- (void)showMachinesWindowAndActivate:(BOOL)activate {
  NSWindowController *controller =
      [self buildSwiftUIMachinesWindowController:nil];
  if (controller) {
    self.macMachinesController = controller;
  }
  if (!self.macMachinesController) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Machines UI Unavailable";
    alert.informativeText =
        @"SwiftUI machines view failed to load. Regenerate the Xcode project and rebuild.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    return;
  }
  if (activate) {
    [NSApp activateIgnoringOtherApps:YES];
  }
  [self.macMachinesController showWindow:nil];
}

- (void)showMachinesWindowFromMenu:(id)sender {
  (void)sender;
  [self showMachinesWindowAndActivate:YES];
}
#endif

@end
