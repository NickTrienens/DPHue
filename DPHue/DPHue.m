//
//  DPHue.m
//  Pods
//
//  Created by Jason Dreisbach on 5/2/13.
//
//

#import "DPHue.h"

NSString *const kHueUsernamePrefKey = @"HueAPIUsernamePrefKey";


@interface DPHue ()
{
    DPHueDiscover *_dhd;
    NSMutableArray *_bridges;
}

@property (readwrite) BOOL isSearching;

@end

@implementation DPHue

+ (id)sharedInstance
{
    static DPHue *sharedHueInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHueInstance = [[DPHue alloc] init];
    });
    return sharedHueInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _bridges = [NSMutableArray array];
        _isSearching = NO;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs objectForKey:kHueUsernamePrefKey] == nil) {
            NSString *username = [DPHueBridge generateUsername];
            [prefs setObject:username forKey:kHueUsernamePrefKey];
            [prefs synchronize];
        }
    }
    return self;
}

- (void)startDiscovery
{
    if (_dhd == nil)
        _dhd = [[DPHueDiscover alloc] initWithDelegate:self];
    
    if (_isSearching == NO) {
        self.isSearching = YES;
        [_dhd discoverForDuration:0 withCompletion:^(NSMutableString *log) {
        }];
    }
}

- (void)cancelDiscovery
{
    [_dhd stopDiscovery];
    self.isSearching = NO;
    _dhd = nil;
}

- (NSArray *)bridges
{
    return _bridges;
}

- (NSArray *)lights
{
    NSMutableArray *lightArray = [NSMutableArray array];
    for (DPHueBridge *bridge in _bridges) {
        [lightArray addObjectsFromArray:bridge.lights];
    }
    return lightArray;
}

+ (NSSet *)keyPathsForValuesAffectingLights
{
    return [NSSet setWithArray:@[@"bridges"]];
}

- (void)reloadBridgeData
{
    [self willChangeValueForKey:@"bridges"];
    for (DPHueBridge *bridge in _bridges) {
        [bridge read];
    }
    [self didChangeValueForKey:@"bridges"];
}

#pragma mark - DPHueDiscover delegate

- (void)foundHueAt:(NSString *)host discoveryLog:(NSMutableString *)log {
    for (DPHueBridge *existingBridge in _bridges) {
        if ([existingBridge.host isEqualToString:host])
            return;
    }
    DPHueBridge *newHue = [[DPHueBridge alloc] initWithHueHost:host username:[[NSUserDefaults standardUserDefaults] objectForKey:kHueUsernamePrefKey]];
    
    [newHue readWithCompletion:^(DPHueBridge *hue, NSError *err) {
        if (err == nil) {
            if (hue.authenticated == YES) {
                [self willChangeValueForKey:@"bridges"];
                [_bridges addObject:hue];
                [self cancelDiscovery];
                [self didChangeValueForKey:@"bridges"];
            }
            else {
                [hue registerUsername];
                if ([_delegate respondsToSelector:@selector(alertUserToPressLinkButtonOnBridge:)]) {
                    [_delegate alertUserToPressLinkButtonOnBridge:hue];
                }
                else {
                    NSLog(@"Found Hue. Press the bridge button to complete registration!");
                }
            }
        }
        else {
            NSLog(@"Could not read hue: %@", err);
        }
    }];
}

@end