//
//  DPHue.h
//  Pods
//
//  Created by Jason Dreisbach on 2/8/13.
//
//

#import <Foundation/Foundation.h>
#import <DPHue/DPHueBridge.h>
#import <DPHue/DPHueLight.h>
#import <DPHue/DPHueDiscover.h>
#import <DPHue/DPHueSchedule.h>

@protocol DPHueDelegate <NSObject>
@optional
- (void)alertUserToPressLinkButtonOnBridge:(DPHueBridge *)bridge;
@end

@interface DPHue : NSObject <DPHueDiscoverDelegate>

@property (readonly) BOOL isSearching;
@property (readonly) NSArray *bridges;
@property (readonly) NSArray *lights;

@property (weak) id <DPHueDelegate> delegate;

+ (id)sharedInstance;

- (void)startDiscovery;
- (void)cancelDiscovery;

- (void)reloadBridgeData;

@end
