//
//  DPHueSchedule.h
//  Pods
//
//  Created by Jason Dreisbach on 5/12/13.
//
//

#import "DPHueObject.h"

@interface DPHueSchedule : DPHueObject

@property (strong) NSString *identifer;

@property (strong) NSString *name;
@property (strong) NSString *scheduleDescription;
@property (strong) NSDictionary *command;
@property (strong) NSDate *date;

@end
