//
//  DPHueLightState.m
//  Pods
//
//  Created by Jason Dreisbach on 2/9/13.
//
//

#import "DPHueLightState.h"
#import "DPHueLight.h"
#import "DPHueBridge.h"

@implementation DPHueLightState

- (id)initWithBridge:(DPHueBridge *)bridge light:(DPHueLight *)light
{
    self = [super initWithBridge:bridge];
    if (self != nil) {
        _light = light;
    }
    return self;
}

- (NSString *)address
{
    return [NSString stringWithFormat:@"/api/%@/lights/%@/state", self.bridge.username, self.light.number];
}

- (void)writeAll {
    if (!self.light.on) {
        // If bulb is off, it forbids changes, so send none
        // except to turn it off
        self.pendingChanges[@"on"] = [NSNumber numberWithBool:self.light.on];
        [self write];
        return;
    }
    self.pendingChanges[@"on"] = [NSNumber numberWithBool:self.light.on];
    self.pendingChanges[@"bri"] = self.light.brightness;
    // colorMode is set by the bulb itself
    // whichever color value you sent it last determines the mode
    if ([self.light.colorMode isEqualToString:@"hue"]) {
        self.pendingChanges[@"hue"] = self.light.hue;
        self.pendingChanges[@"sat"] = self.light.saturation;
    }
    if ([self.light.colorMode isEqualToString:@"xy"]) {
        self.pendingChanges[@"xy"] = self.light.xy;
    }
    if ([self.light.colorMode isEqualToString:@"ct"]) {
        self.pendingChanges[@"ct"] = self.light.colorTemperature;
    }
    [self write];
}


- (void)write {
    if (self.pendingChanges.count == 0)
        return;
    if (self.light.transitionTime) {
        self.pendingChanges[@"transitiontime"] = self.light.transitionTime;
		self.light.transitionTime = nil;
    }
    [super write];
}

@end
