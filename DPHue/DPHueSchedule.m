//
//  DPHueSchedule.m
//  Pods
//
//  Created by Jason Dreisbach on 5/12/13.
//
//

#import "DPHueSchedule.h"
#import "DPHueBridge.h"

@implementation DPHueSchedule

- (NSString *)address
{
    return [NSString stringWithFormat:@"/api/%@/schedules", self.bridge.username];
}

- (void)write {
    
    NSMutableDictionary *postData = [NSMutableDictionary dictionary];
    
    if (_name.length > 0)
        postData[@"name"] = _name;
    
    // TODO: make sure this doesn't get past 64 characters
    if (_scheduleDescription.length > 0)
        postData[@"description"] = _scheduleDescription;
    
    // TODO: make sure this doesn't get past 90 characters
    if (_command.count > 0)
        postData[@"command"] = _command;
    
    if (_date != nil) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'S'"];
        postData[@"time"] = [formatter stringFromDate:_date];
    }
    
    NSData *json = [NSJSONSerialization dataWithJSONObject:postData options:0 error:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = self.URL;
    request.HTTPMethod = self.identifer.length > 0 ? @"PUT" : @"POST";
    request.HTTPBody = json;
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:request];
    connection.jsonRootObject = self;
    connection.completionBlock = ^(id obj, NSError *err) {
        
    };
    [connection start];
}

- (void)readFromJSONDictionary:(id)d
{
    if (![d respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        // We were given an array, not a dict, which means
        // the Hue is telling us the result of a PUT
        // Loop through all results, if any are not successful, error out
        BOOL errorFound = NO;
        
        for (NSDictionary *result in d) {
            if (result[@"error"]) {
                errorFound = YES;
                NSLog(@"%@", result[@"error"]);
            }
            if (result[@"success"]) {
                NSLog(@"%@", result[@"success"]);
            }
        }
    }
}

@end
