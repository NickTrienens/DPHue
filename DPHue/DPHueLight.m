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
#import "DPHueBridge.h"

@interface DPHueLight ()
{
    BOOL _readingState;
    
}

@property (nonatomic, readwrite) BOOL reachable;
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *modelid;
@property (nonatomic, strong, readwrite) NSString *colorMode;

@end

@implementation DPHueLight

+ (NSDictionary *)propertyKeyToJSONKeyDictionary
{
    static NSDictionary *propertyDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertyDictionary = @{
                               @"name": @"name",
                               @"on" : @"on",
                               @"brightness" : @"bri",
                               @"hue" : @"hue",
                               @"saturation" : @"sat",
                               @"xy" : @"xy",
                               @"colorTemperature" : @"ct",
                               };
    });
    return propertyDictionary;
}

- (id)initWithBridge:(DPHueBridge *)bridge {
    self = [super initWithBridge:bridge];
    if (self) {
        
        self.holdUpdates = YES;
        _readingState = NO;
        
        NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
        [self addObserver:self forKeyPath:@"name" options:options context:nil];
        [self addObserver:self forKeyPath:@"on" options:options context:nil];
        [self addObserver:self forKeyPath:@"brightness" options:options context:nil];
        [self addObserver:self forKeyPath:@"hue" options:options context:nil];
        [self addObserver:self forKeyPath:@"saturation" options:options context:nil];
        [self addObserver:self forKeyPath:@"xy" options:options context:nil];
        [self addObserver:self forKeyPath:@"colorTemperature" options:options context:nil];
        
        self.state = [[DPHueLightState alloc] initWithBridge:self.bridge light:self];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"on"];
    [self removeObserver:self forKeyPath:@"brightness"];
    [self removeObserver:self forKeyPath:@"hue"];
    [self removeObserver:self forKeyPath:@"saturation"];
    [self removeObserver:self forKeyPath:@"xy"];
    [self removeObserver:self forKeyPath:@"colorTemperature"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self) && (_readingState == NO)) {
        
        DPHueObject *changedObject = nil;
        if ([keyPath isEqualToString:@"name"]) {
            changedObject = self;
        }
        else {
            changedObject = self.state;
        }
        
        id changedProperty = nil;
        if ([keyPath isEqualToString:@"on"]) {
            changedProperty = [NSNumber numberWithBool:[[object valueForKey:keyPath] boolValue]];
        }
        else {
            changedProperty = [object valueForKey:keyPath];
        }
        
		/*
        if ([change[NSKeyValueChangeNewKey] isEqual:change[NSKeyValueChangeOldKey]])
            return;
		 */
        
        [changedObject.pendingChanges setObject:changedProperty forKey:[[self class] propertyKeyToJSONKeyDictionary][keyPath]];
        
        if (_holdUpdates == NO)
            [self write];
    }
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
    [descr appendFormat:@"\tPending changes: %@\n", self.state.pendingChanges];
    return descr;
}

- (NSString *)address
{
    return [NSString stringWithFormat:@"/api/%@/lights/%@", self.bridge.username, self.number];
}

#pragma mark - LightState write through

+ (NSSet *)keyPathsForValuesAffectingColor
{
    return [NSSet setWithArray:@[@"colorMode", @"hue", @"saturation", @"colorTemperature"]];
}

#if TARGET_OS_IPHONE
- (void)setColor:(UIColor *)color
{
    BOOL holdUpdates = self.holdUpdates;
    _holdUpdates = YES;
	float h, s, b, a;
	[color getHue:&h saturation:&s brightness:&b alpha:&a];
	
    self.hue = @(h * 65535);
    self.saturation = @(s * 255);
    self.brightness = @(b * 255);
    self.colorMode = @"hs";
    _holdUpdates = holdUpdates;
    if (!self.holdUpdates)
        [self.state write];
}

- (UIColor *)color
{
    return [self colorForColorMode:_colorMode];
}

- (UIColor *)colorForColorMode:(NSString *)colorMode
{
    UIColor *currentColor = [UIColor blackColor];
    if ([colorMode isEqualToString:@"hs"] || [colorMode isEqualToString:@"xy"]) {
        currentColor =  [UIColor colorWithHue:([_hue integerValue]/65535.0) saturation:([_saturation integerValue]/255.0) brightness:([_brightness integerValue]/255.0) alpha:1.0];
    }
    else if ([colorMode isEqualToString:@"ct"]) {
        // Convert color temperature to RGB
        //http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
        CGFloat red, green, blue;
        // kelvin = 1M / mireds
        double kelvin = 1.0e6 / [_colorTemperature doubleValue];
        // Divide by 100
        kelvin = kelvin / 100.0;
        
        // Red
        if (kelvin <= 66) {
            red = 255;
        }
        else {
            red = kelvin - 60;
            // 329.698727446/255.0 = 1.29293618606275
            red = 329.698727446 * pow(red, -0.1332047592);
        }
        red /= 255.0;
        
        // Green
        if (kelvin <= 66) {
            green = 99.4708025861 * log(kelvin) - 161.1195681661;
        }
        else {
            green = kelvin - 60;
            green = 288.1221695283 * pow(green, -0.0755148492);
        }
        green /= 255.0;
        
        // Blue
        if (kelvin >= 66) {
            blue = 255.0;
        }
        else {
            if (kelvin <= 19) {
                blue = 0.0;
            }
            else {
                blue = kelvin - 10;
                blue = 138.5177312231 * log(blue) - 305.0447927307;
            }
        }
        blue /= 255.0;
        
        currentColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    }

    return currentColor;
}
- (void)setBrightness:(NSNumber *)brightness {
    [self willChangeValueForKey:@"brightness"];
    brightness = [brightness floatValue] > 255 ? @255 : brightness;
    brightness = [brightness floatValue] < 0 ? @0 : brightness;
    _brightness = @([brightness integerValue]);
    [self didChangeValueForKey:@"brightness"];
}

- (void)setHue:(NSNumber *)hue {
    [self willChangeValueForKey:@"hue"];
    hue = [hue floatValue] > 65535 ? @65535 : hue;
    hue = [hue floatValue] < 0 ? @0 : hue;
    _hue = @([hue integerValue]);
    [self didChangeValueForKey:@"hue"];
}

- (void)setSaturation:(NSNumber *)saturation {
    [self willChangeValueForKey:@"saturation"];
    saturation = [saturation floatValue] > 255 ? @255 : saturation;
    saturation = [saturation floatValue] < 0 ? @0 : saturation;
    _saturation = @([saturation integerValue]);
    [self didChangeValueForKey:@"saturation"];
}

- (void)setColorTemperature:(NSNumber *)colorTemperature {
    [self willChangeValueForKey:@"colorTemperature"];
    colorTemperature = [colorTemperature floatValue] > 500 ? @500 : colorTemperature;
    colorTemperature = [colorTemperature floatValue] < 154 ? @154 : colorTemperature;
    _colorTemperature = @([colorTemperature integerValue]);
    [self didChangeValueForKey:@"colorTemperature"];
}

#else
- (void)setColor:(NSColor *)color
{
    BOOL holdUpdates = self.holdUpdates;
    _holdUpdates = YES;
    color = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    self.hue = [NSNumber numberWithDouble:[color hueComponent] * 65535];
    self.saturation = [NSNumber numberWithDouble:[color saturationComponent] * 255];
    self.brightness = [NSNumber numberWithDouble:[color brightnessComponent] * 255];
    self.colorMode = @"hs";
    _holdUpdates = holdUpdates;
    if (!self.holdUpdates)
        [self.state write];
}

- (NSColor *)color
{
    return [self colorForColorMode:_colorMode];
}

- (NSColor *)colorForColorMode:(NSString *)colorMode
{
    NSColor *currentColor = [NSColor blackColor];
    if ([colorMode isEqualToString:@"hs"] || [colorMode isEqualToString:@"xy"]) {
        currentColor =  [NSColor colorWithCalibratedHue:([_hue integerValue]/65535.0) saturation:([_saturation integerValue]/255.0) brightness:([_brightness integerValue]/255.0) alpha:1.0];
    }
    else if ([colorMode isEqualToString:@"ct"]) {
        // Convert color temperature to RGB
        //http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
        CGFloat red, green, blue;
        // kelvin = 1M / mireds
        double kelvin = 1.0e6 / [_colorTemperature doubleValue];
        // Divide by 100
        kelvin = kelvin / 100.0;
        
        // Red
        if (kelvin <= 66) {
            red = 255;
        }
        else {
            red = kelvin - 60;
            // 329.698727446/255.0 = 1.29293618606275
            red = 329.698727446 * pow(red, -0.1332047592);
        }
        red /= 255.0;
        
        // Green
        if (kelvin <= 66) {
            green = 99.4708025861 * log(kelvin) - 161.1195681661;
        }
        else {
            green = kelvin - 60;
            green = 288.1221695283 * pow(green, -0.0755148492);
        }
        green /= 255.0;
        
        // Blue
        if (kelvin >= 66) {
            blue = 255.0;
        }
        else {
            if (kelvin <= 19) {
                blue = 0.0;
            }
            else {
                blue = kelvin - 10;
                blue = 138.5177312231 * log(blue) - 305.0447927307;
            }
        }
        blue /= 255.0;
        
        currentColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0];
    }

    return currentColor;
}

- (void)setBrightness:(NSNumber *)brightness {
    [self willChangeValueForKey:@"brightness"];
    brightness = [brightness isGreaterThan:@255] ? @255 : brightness;
    brightness = [brightness isLessThan:@0] ? @0 : brightness;
    _brightness = @([brightness integerValue]);
    [self didChangeValueForKey:@"brightness"];
}

- (void)setHue:(NSNumber *)hue {
    [self willChangeValueForKey:@"hue"];
    hue = [hue isGreaterThan:@65535] ? @65535 : hue;
    hue = [hue isLessThan:@0] ? @0 : hue;
    _hue = @([hue integerValue]);
    [self didChangeValueForKey:@"hue"];
}

- (void)setSaturation:(NSNumber *)saturation {
    [self willChangeValueForKey:@"saturation"];
    saturation = [saturation isGreaterThan:@255] ? @255 : saturation;
    saturation = [saturation isLessThan:@0] ? @0 : saturation;
    _saturation = @([saturation integerValue]);
    [self didChangeValueForKey:@"saturation"];
}

- (void)setColorTemperature:(NSNumber *)colorTemperature {
    [self willChangeValueForKey:@"colorTemperature"];
    colorTemperature = [colorTemperature isGreaterThan:@500] ? @500 : colorTemperature;
    colorTemperature = [colorTemperature isLessThan:@154] ? @154 : colorTemperature;
    _colorTemperature = @([colorTemperature integerValue]);
    [self didChangeValueForKey:@"colorTemperature"];
}
#endif

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
        _readingState = YES;
        
        self.name = d[@"name"] ?: _name;
        self.on = [d[@"state"][@"on"] boolValue];
        self.colorMode = d[@"state"][@"colormode"] ?: _colorMode;
        
        self.brightness = d[@"state"][@"bri"] ?: _brightness;
        
        self.hue = d[@"state"][@"hue"] ?: _hue;
        self.saturation = d[@"state"][@"sat"] ?: _saturation;
        self.xy = d[@"state"][@"xy"] ?: _xy;
        self.colorTemperature = d[@"state"][@"ct"] ?: _colorTemperature;
        
        self.reachable = [d[@"state"][@"reachable"] boolValue];
        self.modelid = d[@"modelid"] ?: _modelid;
        self.swversion = d[@"swversion"] ?: _swversion;
        self.type = d[@"type"] ?: _type;
        
        _readingState = NO;
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super initWithCoder:a];
    if (self) {
        self.holdUpdates = YES;
        _readingState = YES;
        
        self.number = [a decodeObjectForKey:@"number"];
        
        self.name = [a decodeObjectForKey:@"name"];
        
        self.on = [[a decodeObjectForKey:@"on"] boolValue];
        
        self.colorMode = [a decodeObjectForKey:@"colorMode"];
        
        self.brightness = [a decodeObjectForKey:@"brightness"];
        
        self.hue = [a decodeObjectForKey:@"hue"];
        
        self.xy = [a decodeObjectForKey:@"xy"];
        self.colorTemperature = [a decodeObjectForKey:@"colorTemperature"];
        self.saturation = [a decodeObjectForKey:@"saturation"];
        
        
        self.modelid = [a decodeObjectForKey:@"modelid"];
        self.swversion = [a decodeObjectForKey:@"swversion"];
        self.type = [a decodeObjectForKey:@"type"];
        
        _readingState = NO;
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
    [a encodeObject:[NSNumber numberWithBool:self->_on] forKey:@"on"];
    [a encodeObject:_xy forKey:@"xy"];
    [a encodeObject:_colorTemperature forKey:@"colorTemperature"];
    [a encodeObject:_saturation forKey:@"saturation"];
    [a encodeObject:_number forKey:@"number"];
}

@end
