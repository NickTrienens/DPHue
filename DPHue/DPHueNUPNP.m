//
//  DPHueNUPNP.m
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

#import "DPHueNUPNP.h"

@implementation DPHueNUPNP

- (void)readFromJSONDictionary:(id)d {
    if ([d count] > 0) {
        NSDictionary *dict = [d objectAtIndex:0];
        _hueID = dict[@"id"];
        _hueIP = dict[@"internalipaddress"];
        _hueMACAddress = dict[@"macaddress"];
		if (!_hueMACAddress) {
			NSMutableString *mac = [_hueID mutableCopy];
			[mac deleteCharactersInRange:NSMakeRange(6, 4)];
			for (int i = 2 ; i < mac.length ; i += 3) {
				[mac insertString:@":" atIndex:i];
			}
			_hueMACAddress = mac;
		}
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ID: %@\nIP: %@\nMAC: %@\n", self.hueID, self.hueIP, self.hueMACAddress];
}

@end
