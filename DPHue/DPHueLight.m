//
//  DPHueLight.m
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

#import "DPHueLight.h"
#import "WSLog.h"
#import "DPHueLightState.h"
#import "DPHueBridge.h"

@interface DPHueLight ()

@property (nonatomic, strong) DPHueLightState *state;

@property (nonatomic, readwrite) BOOL reachable;
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *modelid;
@property (nonatomic, strong, readwrite) NSString *colorMode;

@end

@implementation DPHueLight

- (id)initWithBridge:(DPHueBridge *)bridge {
    self = [super initWithBridge:bridge];
    if (self) {
        self.holdUpdates = YES;
        self.state = [[DPHueLightState alloc] initWithBridge:self.bridge light:self];
    }
    return self;
}

- (NSString *)description {
    NSMutableString *descr = [[NSMutableString alloc] init];
    [descr appendFormat:@"Light Name: %@\n", self.name];
    [descr appendFormat:@"\tURL: %@\n", self.URL];
    [descr appendFormat:@"\tNumber: %@\n", self.number];
    [descr appendFormat:@"\tType: %@\n", self.type];
    [descr appendFormat:@"\tVersion: %@\n", self.swversion];
    [descr appendFormat:@"\tModel ID: %@\n", self.modelid];
    [descr appendFormat:@"\tOn: %@\n", self.on ? @"True" : @"False"];
    [descr appendFormat:@"\tBrightness: %@\n", self.brightness];
    [descr appendFormat:@"\tColor Mode: %@\n", self.colorMode];
    [descr appendFormat:@"\tHue: %@\n", self.hue];
    [descr appendFormat:@"\tSaturation: %@\n", self.saturation];
    [descr appendFormat:@"\tColor Temperature: %@\n", self.colorTemperature];
    [descr appendFormat:@"\txy: %@\n", self.xy];
    [descr appendFormat:@"\tPending changes: %@\n", self.pendingChanges];
    return descr;
}

- (NSURL *)URL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@/lights/%@", self.bridge.host, self.bridge.username, self.number]];
}

#pragma mark - Setters that update pendingChanges

- (void)setName:(NSString *)name {
    _name = name;
    self.pendingChanges[@"name"] = name;
    if (!self.holdUpdates)
        [self write];
}

#pragma mark - LightState write through

- (void)setOn:(BOOL)on {
    _on = on;
    self.state.pendingChanges[@"on"] = [NSNumber numberWithBool:on];
    if (!self.holdUpdates)
        [self.state write];
}

- (void)setColor:(NSColor *)color {
    BOOL holdUpdates = self.holdUpdates;
    _holdUpdates = YES;
    [self setHue:[NSNumber numberWithDouble:[color hueComponent] * 65535]];
    [self setSaturation:[NSNumber numberWithDouble:[color saturationComponent] * 255]];
    [self setBrightness:[NSNumber numberWithDouble:[color brightnessComponent] * 255]];
    _color = color;
    _holdUpdates = holdUpdates;
    if (!self.holdUpdates)
        [self.state write];
}

- (void)setBrightness:(NSNumber *)brightness {
    brightness = [brightness isGreaterThan:@255] ? @255 : brightness;
    brightness = [brightness isLessThan:@0] ? @0 : brightness;
    _brightness = @([brightness integerValue]);
    self.state.pendingChanges[@"bri"] = _brightness;
    if (!self.holdUpdates)
        [self.state write];
}

- (void)setHue:(NSNumber *)hue {
    hue = [hue isGreaterThan:@65535] ? @65535 : hue;
    hue = [hue isLessThan:@0] ? @0 : hue;
    _hue = @([hue integerValue]);
    self.state.pendingChanges[@"hue"]  = _hue;
    if (!self.holdUpdates)
        [self.state write];
}

// This is the closest I've ever come to unintentionally naming a method "sexy"
- (void)setXy:(NSArray *)xy {
    _xy = xy;
    self.state.pendingChanges[@"xy"] = _xy;
    if (!self.holdUpdates)
        [self.state write];
}

- (void)setColorTemperature:(NSNumber *)colorTemperature {
    colorTemperature = [colorTemperature isGreaterThan:@500] ? @500 : colorTemperature;
    colorTemperature = [colorTemperature isLessThan:@154] ? @154 : colorTemperature;
    _colorTemperature = @([colorTemperature integerValue]);
    self.state.pendingChanges[@"ct"] = _colorTemperature;
    if (!self.holdUpdates)
        [self.state write];
}

- (void)setSaturation:(NSNumber *)saturation {
    saturation = [saturation isGreaterThan:@255] ? @255 : saturation;
    saturation = [saturation isLessThan:@0] ? @0 : saturation;
    _saturation = @([saturation integerValue]);
    self.state.pendingChanges[@"sat"] = _saturation;
    if (!self.holdUpdates)
        [self.state write];
}
#pragma mark - Write

- (void)writeAll {
    self.pendingChanges[@"name"] = self.name;
    if (!self.state.light.on) {
        // If bulb is off, it forbids changes, so send none
        // except to turn it off
        self.state.pendingChanges[@"on"] = [NSNumber numberWithBool:self.on];
        [self write];
        return;
    }
    self.state.pendingChanges[@"on"] = [NSNumber numberWithBool:self.on];
    self.state.pendingChanges[@"bri"] = self.brightness;
    // colorMode is set by the bulb itself
    // whichever color value you sent it last determines the mode
    if ([self.state.light.colorMode isEqualToString:@"hue"]) {
        self.state.pendingChanges[@"hue"] = self.hue;
        self.state.pendingChanges[@"sat"] = self.saturation;
    }
    if ([self.colorMode isEqualToString:@"xy"]) {
        self.state.pendingChanges[@"xy"] = self.xy;
    }
    if ([self.colorMode isEqualToString:@"ct"]) {
        self.state.pendingChanges[@"ct"] = self.colorTemperature;
    }
    [self write];
}

- (void)write {
    [self.state write];
    if (self.pendingChanges.count == 0)
        return;
    [super write];
}

#pragma mark - DSJSONSerializable

- (void)readFromJSONDictionary:(id)d {
    [super readFromJSONDictionary:d];
    if ([d respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        _name = d[@"name"] ?: _name;
        _modelid = d[@"modelid"] ?: _modelid;
        _swversion = d[@"swversion"] ?: _swversion;
        _type = d[@"type"] ?: _type;
        _brightness = d[@"state"][@"bri"] ?: _brightness;
        _colorMode = d[@"state"][@"colormode"] ?: _colorMode;
        _hue = d[@"state"][@"hue"] ?: _hue;
        _type = d[@"type"] ?: _type;
        _on = (BOOL)d[@"state"][@"on"] ?: _on;
        _reachable = (BOOL)d[@"state"][@"reachable"] ?: _reachable;
        _xy = d[@"state"][@"xy"];
        _colorTemperature = d[@"state"][@"ct"] ?: _colorTemperature;
        _saturation = d[@"state"][@"sat"] ?: _saturation;
        _color = [NSColor colorWithDeviceHue:([_hue integerValue]/65535.0) saturation:([_saturation integerValue]/255.0) brightness:([_brightness integerValue]/255.0) alpha:1.0];
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super initWithCoder:a];
    if (self) {
        self.holdUpdates = YES;
        _name = [a decodeObjectForKey:@"name"];
        _modelid = [a decodeObjectForKey:@"modelid"];
        _swversion = [a decodeObjectForKey:@"swversion"];
        _type = [a decodeObjectForKey:@"type"];
        _brightness = [a decodeObjectForKey:@"brightness"];
        _colorMode = [a decodeObjectForKey:@"colorMode"];
        _hue = [a decodeObjectForKey:@"hue"];
        _type = [a decodeObjectForKey:@"bulbType"];
        _on = [[a decodeObjectForKey:@"on"] boolValue];
        _xy = [a decodeObjectForKey:@"xy"];
        _colorTemperature = [a decodeObjectForKey:@"colorTemperature"];
        _saturation = [a decodeObjectForKey:@"saturation"];
        _number = [a decodeObjectForKey:@"number"];
        _color = [NSColor colorWithDeviceHue:([_hue integerValue]/65535.0) saturation:([_saturation integerValue]/255.0) brightness:([_brightness integerValue]/255.0) alpha:1.0];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [super encodeWithCoder:a];
    [a encodeObject:_name forKey:@"name"];
    [a encodeObject:_modelid forKey:@"modelid"];
    [a encodeObject:_swversion forKey:@"swversion"];
    [a encodeObject:_type forKey:@"type"];
    [a encodeObject:_brightness forKey:@"brightness"];
    [a encodeObject:_colorMode forKey:@"colorMode"];
    [a encodeObject:_hue forKey:@"hue"];
    [a encodeObject:_type forKey:@"bulbType"];
    [a encodeObject:[NSNumber numberWithBool:self->_on] forKey:@"on"];
    [a encodeObject:_xy forKey:@"xy"];
    [a encodeObject:_colorTemperature forKey:@"colorTemperature"];
    [a encodeObject:_saturation forKey:@"saturation"];
    [a encodeObject:_number forKey:@"number"];
}

@end
