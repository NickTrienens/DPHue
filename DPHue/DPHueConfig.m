//
//  DPHueConfig.m
//  Pods
//
//  Created by Jason Dreisbach on 2/8/13.
//
//

#import "DPHueConfig.h"
#import "DPHueBridge.h"

@implementation DPHueConfig

- (NSURL *)URL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@/config", self.bridge.host, self.bridge.username]];
}

- (void)writeAll {
    self.pendingChanges[@"name"] = self.bridge.name;
    [self write];
}

@end
