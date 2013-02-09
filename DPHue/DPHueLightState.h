//
//  DPHueLightState.h
//  Pods
//
//  Created by Jason Dreisbach on 2/9/13.
//
//

#import "DPHueObject.h"

@class DPHueLight;

@interface DPHueLightState : DPHueObject

- (id)initWithBridge:(DPHueBridge *)bridge light:(DPHueLight *)light;

@property (nonatomic, weak) DPHueLight *light;

@end
