//
//  DPHueObject.h
//  Pods
//
//  Created by Jason Dreisbach on 2/8/13.
//
//

#import <Foundation/Foundation.h>
#import "DPJSONSerializable.h"
#import "DPJSONConnection.h"

@class DPHueBridge;

@interface DPHueObject : NSObject <DPJSONSerializable, NSCoding>

- (id)initWithBridge:(DPHueBridge *)bridge;

@property (nonatomic, weak) DPHueBridge *bridge;

@property (readonly) NSMutableDictionary *pendingChanges;

- (NSString *)address;
- (NSURL *)URL;

// Re-download & parse controller's state for this particular light
- (void)read;
- (void)readWithCompletion:(void (^)(id object, NSError *err))block;

// Write only pending changes to controller
- (void)write;

// Write entire state to controller, regardless of changes
- (void)writeAll;


@end

