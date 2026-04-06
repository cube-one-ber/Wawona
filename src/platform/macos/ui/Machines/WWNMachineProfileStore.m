#import "WWNMachineProfileStore.h"
#import "../Settings/WWNPreferencesManager.h"

NSString *const kWWNMachineTypeSSHWaypipe = @"ssh_waypipe";
NSString *const kWWNMachineTypeSSHTerminal = @"ssh_terminal";
NSString *const kWWNMachineTypeNative = @"native";
NSString *const kWWNMachineTypeVirtualMachine = @"virtual_machine";
NSString *const kWWNMachineTypeContainer = @"container";

static NSString *const kWWNMachineProfilesJSON = @"wawona.machineProfiles.v1";
static NSString *const kWWNActiveMachineId = @"wawona.activeMachineId.v1";
static NSString *const kWWNMachineProfilesMigrated = @"wawona.machineProfilesMigrated.v1";
static NSString *const kWWNMachineSettingsOverrides = @"settingsOverrides";
static BOOL sPersistingMachineSettings = NO;

@implementation WWNMachineProfile

+ (instancetype)defaultProfile {
  return [[WWNMachineProfile alloc] initDefaultProfile];
}

- (instancetype)initDefaultProfile {
  self = [super init];
  if (self) {
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    _machineId = [NSUUID UUID].UUIDString;
    _name = @"Default Machine";
    _type = kWWNMachineTypeSSHWaypipe;
    _sshEnabled = YES;
    _sshHost = @"";
    _sshUser = @"";
    _sshPassword = @"";
    _sshBinary = @"ssh";
    _sshAuthMethod = 0;
    _sshKeyPath = @"";
    _sshKeyPassphrase = @"";
    _remoteCommand = @"";
    _customScript = @"";
    _vmSubtype = @"qemu";
    _containerSubtype = @"docker";
    _waypipeCompress = @"lz4";
    _waypipeThreads = @"0";
    _waypipeVideo = @"none";
    _waypipeDebug = NO;
    _waypipeOneshot = NO;
    _waypipeDisableGpu = NO;
    _waypipeLoginShell = NO;
    _waypipeTitlePrefix = @"";
    _waypipeSecCtx = @"";
    _settingsOverrides = @{};
    _favorite = NO;
    _createdAtMs = now;
    _updatedAtMs = now;
  }
  return self;
}

- (NSDictionary *)serialize {
  return @{
    @"id" : self.machineId ?: @"",
    @"name" : self.name ?: @"Unnamed Machine",
    @"type" : self.type ?: kWWNMachineTypeSSHWaypipe,
    @"sshEnabled" : @(self.sshEnabled),
    @"sshHost" : self.sshHost ?: @"",
    @"sshUser" : self.sshUser ?: @"",
    @"sshPassword" : self.sshPassword ?: @"",
    @"sshBinary" : self.sshBinary ?: @"ssh",
    @"sshAuthMethod" : @(self.sshAuthMethod),
    @"sshKeyPath" : self.sshKeyPath ?: @"",
    @"sshKeyPassphrase" : self.sshKeyPassphrase ?: @"",
    @"remoteCommand" : self.remoteCommand ?: @"",
    @"customScript" : self.customScript ?: @"",
    @"vmSubtype" : self.vmSubtype ?: @"qemu",
    @"containerSubtype" : self.containerSubtype ?: @"docker",
    @"waypipeCompress" : self.waypipeCompress ?: @"lz4",
    @"waypipeThreads" : self.waypipeThreads ?: @"0",
    @"waypipeVideo" : self.waypipeVideo ?: @"none",
    @"waypipeDebug" : @(self.waypipeDebug),
    @"waypipeOneshot" : @(self.waypipeOneshot),
    @"waypipeDisableGpu" : @(self.waypipeDisableGpu),
    @"waypipeLoginShell" : @(self.waypipeLoginShell),
    @"waypipeTitlePrefix" : self.waypipeTitlePrefix ?: @"",
    @"waypipeSecCtx" : self.waypipeSecCtx ?: @"",
    kWWNMachineSettingsOverrides : self.settingsOverrides ?: @{},
    @"favorite" : @(self.favorite),
    @"createdAtMs" : @(self.createdAtMs),
    @"updatedAtMs" : @(self.updatedAtMs),
  };
}

@end

@implementation WWNMachineProfileStore

+ (NSArray<NSString *> *)machineScopedSettingsKeys {
  return @[
    kWWNPrefsUniversalClipboard,
    kWWNPrefsForceServerSideDecorations,
    kWWNPrefsAutoScale,
    kWWNPrefsColorOperations,
    kWWNPrefsNestedCompositorsSupport,
    kWWNPrefsRenderMacOSPointer,
    kWWNPrefsMultipleClients,
    kWWNPrefsEnableLauncher,
    kWWNPrefsSwapCmdWithAlt,
    kWWNPrefsTouchInputType,
    kWWNPrefsTCPListenerPort,
    kWWNPrefsWaylandSocketDir,
    kWWNPrefsWaylandDisplayNumber,
    kWWNPrefsEnableVulkanDrivers,
    kWWNPrefsEnableDmabuf,
    kWWNPrefsVulkanDriver,
    kWWNPrefsOpenGLDriver,
    kWWNPrefsRespectSafeArea,
    kWWNPrefsWaypipeDisplay,
    kWWNPrefsWaypipeSocket,
    kWWNPrefsWaypipeCompress,
    kWWNPrefsWaypipeCompressLevel,
    kWWNPrefsWaypipeThreads,
    kWWNPrefsWaypipeVideo,
    kWWNPrefsWaypipeVideoEncoding,
    kWWNPrefsWaypipeVideoDecoding,
    kWWNPrefsWaypipeVideoBpf,
    kWWNPrefsWaypipeSSHEnabled,
    kWWNPrefsWaypipeSSHHost,
    kWWNPrefsWaypipeSSHUser,
    kWWNPrefsWaypipeSSHBinary,
    kWWNPrefsWaypipeSSHAuthMethod,
    kWWNPrefsWaypipeSSHKeyPath,
    kWWNPrefsWaypipeSSHKeyPassphrase,
    kWWNPrefsWaypipeSSHPassword,
    kWWNPrefsWaypipeRemoteCommand,
    kWWNPrefsWaypipeCustomScript,
    kWWNPrefsWaypipeDebug,
    kWWNPrefsWaypipeNoGpu,
    kWWNPrefsWaypipeOneshot,
    kWWNPrefsWaypipeUnlinkSocket,
    kWWNPrefsWaypipeLoginShell,
    kWWNPrefsWaypipeVsock,
    kWWNPrefsWaypipeXwls,
    kWWNPrefsWaypipeTitlePrefix,
    kWWNPrefsWaypipeSecCtx,
    kWWNPrefsMachineVMProviderStub,
    kWWNPrefsMachineVMDefaultVsockStub,
    kWWNPrefsMachineContainerRuntimeStub,
    kWWNPrefsMachineContainerNamespaceStub,
    kWWNPrefsSSHHost,
    kWWNPrefsSSHUser,
    kWWNPrefsSSHAuthMethod,
    kWWNPrefsSSHPassword,
    kWWNPrefsSSHKeyPath,
    kWWNPrefsSSHKeyPassphrase,
    kWWNPrefsWaypipeUseSSHConfig,
    kWWNPrefsEnableTextAssist,
    kWWNPrefsEnableDictation,
    kWWNPrefsWestonSimpleSHMEnabled,
    kWWNPrefsWestonEnabled,
    kWWNPrefsWestonTerminalEnabled,
  ];
}

+ (NSDictionary<NSString *, id> *)captureSettingsSnapshot {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary<NSString *, id> *snapshot = [NSMutableDictionary dictionary];
  for (NSString *key in [self machineScopedSettingsKeys]) {
    id value = [defaults objectForKey:key];
    if (value != nil) {
      snapshot[key] = value;
    }
  }
  return snapshot;
}

+ (void)applySettingsSnapshot:(NSDictionary<NSString *, id> *)snapshot {
  if (snapshot.count == 0) {
    return;
  }
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  for (NSString *key in snapshot) {
    id value = snapshot[key];
    if (value != nil) {
      [defaults setObject:value forKey:key];
    }
  }
}

+ (void)ensureObserverRegistered {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSUserDefaultsDidChangeNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                  (void)note;
                  [self persistActiveMachineSettings];
                }];
  });
}

+ (WWNMachineProfile *)profileFromDictionary:(NSDictionary *)obj {
  WWNMachineProfile *profile = [[WWNMachineProfile alloc] initDefaultProfile];
  NSString *machineId = [obj[@"id"] isKindOfClass:[NSString class]] ? obj[@"id"] : @"";
  profile.machineId = machineId.length > 0 ? machineId : [NSUUID UUID].UUIDString;
  NSString *name = [obj[@"name"] isKindOfClass:[NSString class]] ? obj[@"name"] : @"";
  profile.name = name.length > 0 ? name : @"Unnamed Machine";
  NSString *type = [obj[@"type"] isKindOfClass:[NSString class]] ? obj[@"type"] : @"";
  profile.type = type.length > 0 ? type : kWWNMachineTypeSSHWaypipe;
  profile.sshEnabled = [obj[@"sshEnabled"] respondsToSelector:@selector(boolValue)] ? [obj[@"sshEnabled"] boolValue] : YES;
  profile.sshHost = [obj[@"sshHost"] isKindOfClass:[NSString class]] ? obj[@"sshHost"] : @"";
  profile.sshUser = [obj[@"sshUser"] isKindOfClass:[NSString class]] ? obj[@"sshUser"] : @"";
  profile.sshPassword = [obj[@"sshPassword"] isKindOfClass:[NSString class]] ? obj[@"sshPassword"] : @"";
  profile.sshBinary = [obj[@"sshBinary"] isKindOfClass:[NSString class]] ? obj[@"sshBinary"] : @"ssh";
  profile.sshAuthMethod = [obj[@"sshAuthMethod"] respondsToSelector:@selector(integerValue)] ? [obj[@"sshAuthMethod"] integerValue] : 0;
  profile.sshKeyPath = [obj[@"sshKeyPath"] isKindOfClass:[NSString class]] ? obj[@"sshKeyPath"] : @"";
  profile.sshKeyPassphrase = [obj[@"sshKeyPassphrase"] isKindOfClass:[NSString class]] ? obj[@"sshKeyPassphrase"] : @"";
  profile.remoteCommand = [obj[@"remoteCommand"] isKindOfClass:[NSString class]] ? obj[@"remoteCommand"] : @"";
  profile.customScript = [obj[@"customScript"] isKindOfClass:[NSString class]] ? obj[@"customScript"] : @"";
  profile.vmSubtype = [obj[@"vmSubtype"] isKindOfClass:[NSString class]] ? obj[@"vmSubtype"] : @"qemu";
  profile.containerSubtype = [obj[@"containerSubtype"] isKindOfClass:[NSString class]] ? obj[@"containerSubtype"] : @"docker";
  profile.waypipeCompress = [obj[@"waypipeCompress"] isKindOfClass:[NSString class]] ? obj[@"waypipeCompress"] : @"lz4";
  profile.waypipeThreads = [obj[@"waypipeThreads"] isKindOfClass:[NSString class]] ? obj[@"waypipeThreads"] : @"0";
  profile.waypipeVideo = [obj[@"waypipeVideo"] isKindOfClass:[NSString class]] ? obj[@"waypipeVideo"] : @"none";
  profile.waypipeDebug = [obj[@"waypipeDebug"] respondsToSelector:@selector(boolValue)] ? [obj[@"waypipeDebug"] boolValue] : NO;
  profile.waypipeOneshot = [obj[@"waypipeOneshot"] respondsToSelector:@selector(boolValue)] ? [obj[@"waypipeOneshot"] boolValue] : NO;
  profile.waypipeDisableGpu = [obj[@"waypipeDisableGpu"] respondsToSelector:@selector(boolValue)] ? [obj[@"waypipeDisableGpu"] boolValue] : NO;
  profile.waypipeLoginShell = [obj[@"waypipeLoginShell"] respondsToSelector:@selector(boolValue)] ? [obj[@"waypipeLoginShell"] boolValue] : NO;
  profile.waypipeTitlePrefix = [obj[@"waypipeTitlePrefix"] isKindOfClass:[NSString class]] ? obj[@"waypipeTitlePrefix"] : @"";
  profile.waypipeSecCtx = [obj[@"waypipeSecCtx"] isKindOfClass:[NSString class]] ? obj[@"waypipeSecCtx"] : @"";
  NSDictionary *settingsOverrides = [obj[kWWNMachineSettingsOverrides] isKindOfClass:[NSDictionary class]] ? obj[kWWNMachineSettingsOverrides] : @{};
  profile.settingsOverrides = settingsOverrides;
  profile.favorite = [obj[@"favorite"] respondsToSelector:@selector(boolValue)] ? [obj[@"favorite"] boolValue] : NO;
  profile.createdAtMs = [obj[@"createdAtMs"] respondsToSelector:@selector(longLongValue)] ? [obj[@"createdAtMs"] longLongValue] : profile.createdAtMs;
  profile.updatedAtMs = [obj[@"updatedAtMs"] respondsToSelector:@selector(longLongValue)] ? [obj[@"updatedAtMs"] longLongValue] : profile.updatedAtMs;
  return profile;
}

+ (NSArray<WWNMachineProfile *> *)parseProfilesJSON:(NSString *)raw {
  if (raw.length == 0) {
    return @[];
  }

  NSData *data = [raw dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) {
    return @[];
  }

  NSError *err = nil;
  id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
  if (err || ![parsed isKindOfClass:[NSArray class]]) {
    return @[];
  }

  NSMutableArray<WWNMachineProfile *> *profiles = [NSMutableArray array];
  for (id entry in (NSArray *)parsed) {
    if (![entry isKindOfClass:[NSDictionary class]]) {
      continue;
    }
    [profiles addObject:[self profileFromDictionary:(NSDictionary *)entry]];
  }
  return profiles;
}

+ (void)saveProfiles:(NSArray<WWNMachineProfile *> *)profiles {
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:profiles.count];
  for (WWNMachineProfile *profile in profiles) {
    [arr addObject:[profile serialize]];
  }

  NSError *err = nil;
  NSData *json = [NSJSONSerialization dataWithJSONObject:arr options:0 error:&err];
  if (err || !json) {
    return;
  }

  NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
  [[NSUserDefaults standardUserDefaults] setObject:jsonString forKey:kWWNMachineProfilesJSON];
}

+ (void)migrateFromLegacyPrefsIfNeeded {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL migrated = [defaults boolForKey:kWWNMachineProfilesMigrated];
  NSString *existing = [defaults stringForKey:kWWNMachineProfilesJSON];
  if (migrated || existing.length > 0) {
    return;
  }

  WWNPreferencesManager *prefs = [WWNPreferencesManager sharedManager];
  WWNMachineProfile *profile = [[WWNMachineProfile alloc] initDefaultProfile];
  profile.name = prefs.waypipeSSHHost.length > 0 ? [NSString stringWithFormat:@"Migrated %@", prefs.waypipeSSHHost] : @"Default Machine";
  profile.type = kWWNMachineTypeSSHWaypipe;
  profile.sshEnabled = prefs.waypipeSSHEnabled;
  profile.sshHost = prefs.waypipeSSHHost ?: @"";
  profile.sshUser = prefs.waypipeSSHUser ?: @"";
  profile.sshPassword = prefs.waypipeSSHPassword ?: @"";
  profile.sshBinary = prefs.waypipeSSHBinary ?: @"ssh";
  profile.sshAuthMethod = prefs.waypipeSSHAuthMethod;
  profile.sshKeyPath = prefs.waypipeSSHKeyPath ?: @"";
  profile.sshKeyPassphrase = prefs.waypipeSSHKeyPassphrase ?: @"";
  profile.remoteCommand = prefs.waypipeRemoteCommand ?: @"";
  profile.customScript = prefs.waypipeCustomScript ?: @"";
  profile.waypipeCompress = prefs.waypipeCompress ?: @"lz4";
  profile.waypipeThreads = prefs.waypipeThreads ?: @"0";
  profile.waypipeVideo = prefs.waypipeVideo ?: @"none";
  profile.waypipeDebug = prefs.waypipeDebug;
  profile.waypipeOneshot = prefs.waypipeOneshot;
  profile.waypipeDisableGpu = prefs.waypipeNoGpu;
  profile.waypipeLoginShell = prefs.waypipeLoginShell;
  profile.waypipeTitlePrefix = prefs.waypipeTitlePrefix ?: @"";
  profile.waypipeSecCtx = prefs.waypipeSecCtx ?: @"";
  profile.settingsOverrides = [self captureSettingsSnapshot];

  [self saveProfiles:@[ profile ]];
  [self setActiveMachineId:profile.machineId];
  [defaults setBool:YES forKey:kWWNMachineProfilesMigrated];
}

+ (NSArray<WWNMachineProfile *> *)loadProfiles {
  [self ensureObserverRegistered];
  [self migrateFromLegacyPrefsIfNeeded];
  NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kWWNMachineProfilesJSON];
  return [self parseProfilesJSON:raw];
}

+ (NSArray<WWNMachineProfile *> *)upsertProfile:(WWNMachineProfile *)profile {
  long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  profile.updatedAtMs = now;
  if (profile.createdAtMs == 0) {
    profile.createdAtMs = now;
  }
  if (profile.machineId.length == 0) {
    profile.machineId = [NSUUID UUID].UUIDString;
  }

  NSMutableArray<WWNMachineProfile *> *profiles = [[self loadProfiles] mutableCopy];
  NSUInteger idx = [profiles indexOfObjectPassingTest:^BOOL(WWNMachineProfile *obj, NSUInteger idx, BOOL *stop) {
    (void)idx;
    (void)stop;
    return [obj.machineId isEqualToString:profile.machineId];
  }];
  if (idx == NSNotFound) {
    [profiles addObject:profile];
  } else {
    profiles[idx] = profile;
  }
  [self saveProfiles:profiles];
  return profiles;
}

+ (NSArray<WWNMachineProfile *> *)deleteProfileById:(NSString *)machineId {
  NSArray<WWNMachineProfile *> *current = [self loadProfiles];
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(WWNMachineProfile *obj, NSDictionary *bindings) {
    (void)bindings;
    return ![obj.machineId isEqualToString:machineId];
  }];
  NSArray<WWNMachineProfile *> *filtered = [current filteredArrayUsingPredicate:predicate];
  [self saveProfiles:filtered];
  if ([[self activeMachineId] isEqualToString:machineId]) {
    [self setActiveMachineId:nil];
  }
  return filtered;
}

+ (NSString *)activeMachineId {
  return [[NSUserDefaults standardUserDefaults] stringForKey:kWWNActiveMachineId];
}

+ (void)setActiveMachineId:(NSString *)machineId {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if (machineId.length > 0) {
    [defaults setObject:machineId forKey:kWWNActiveMachineId];
  } else {
    [defaults removeObjectForKey:kWWNActiveMachineId];
  }
}

+ (void)applyMachineToRuntimePrefs:(WWNMachineProfile *)profile {
  [self ensureObserverRegistered];
  [self applySettingsSnapshot:profile.settingsOverrides];
  WWNPreferencesManager *prefs = [WWNPreferencesManager sharedManager];
  [prefs setWaypipeSSHEnabled:profile.sshEnabled];
  [prefs setWaypipeSSHHost:profile.sshHost ?: @""];
  [prefs setWaypipeSSHUser:profile.sshUser ?: @""];
  [prefs setWaypipeSSHPassword:profile.sshPassword ?: @""];
  [prefs setWaypipeSSHBinary:profile.sshBinary ?: @"ssh"];
  [prefs setWaypipeSSHAuthMethod:profile.sshAuthMethod];
  [prefs setWaypipeSSHKeyPath:profile.sshKeyPath ?: @""];
  [prefs setWaypipeSSHKeyPassphrase:profile.sshKeyPassphrase ?: @""];
  [prefs setWaypipeRemoteCommand:profile.remoteCommand ?: @""];
  [prefs setWaypipeCustomScript:profile.customScript ?: @""];
  [prefs setWaypipeCompress:profile.waypipeCompress ?: @"lz4"];
  [prefs setWaypipeThreads:profile.waypipeThreads ?: @"0"];
  [prefs setWaypipeVideo:profile.waypipeVideo ?: @"none"];
  [prefs setWaypipeDebug:profile.waypipeDebug];
  [prefs setWaypipeOneshot:profile.waypipeOneshot];
  [prefs setWaypipeNoGpu:profile.waypipeDisableGpu];
  [prefs setWaypipeLoginShell:profile.waypipeLoginShell];
  [prefs setWaypipeTitlePrefix:profile.waypipeTitlePrefix ?: @""];
  [prefs setWaypipeSecCtx:profile.waypipeSecCtx ?: @""];
}

+ (void)persistActiveMachineSettings {
  if (sPersistingMachineSettings) {
    return;
  }
  NSString *activeId = [self activeMachineId];
  if (activeId.length == 0) {
    return;
  }
  NSArray<WWNMachineProfile *> *profiles = [self loadProfiles];
  WWNMachineProfile *active = nil;
  for (WWNMachineProfile *profile in profiles) {
    if ([profile.machineId isEqualToString:activeId]) {
      active = profile;
      break;
    }
  }
  if (!active) {
    return;
  }
  NSDictionary *snapshot = [self captureSettingsSnapshot];
  if ([active.settingsOverrides isEqualToDictionary:snapshot]) {
    return;
  }
  active.settingsOverrides = snapshot;
  sPersistingMachineSettings = YES;
  [self upsertProfile:active];
  sPersistingMachineSettings = NO;
}

@end
