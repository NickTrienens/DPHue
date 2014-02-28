//
//  DPHueObject.m
//  Pods
//
//  Created by Jason Dreisbach on 2/8/13.
//
//

#import "DPHueObject.h"
#import "DPHueBridge.h"

@implementation DPHueObject

- (id)initWithBridge:(DPHueBridge *)bridge {
    self = [super init];
    if (self != nil) {
        self.bridge = bridge;
        _pendingChanges = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)address
{
    return [NSString stringWithFormat:@"/api/%@", self.bridge.username];
}

- (NSURL *)URL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", self.bridge.host, [self address]]];
}

- (void)read {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.URL];
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.jsonRootObject = self;
    [connection start];
}

- (void)readWithCompletion:(void (^)(id object, NSError *err))block {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.URL];
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.completionBlock = block;
    connection.jsonRootObject = self;
    [connection start];
}

- (void)writeChanges:(NSDictionary *)changes
{
    NSData *json = [NSJSONSerialization dataWithJSONObject:changes options:0 error:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = self.URL;
    request.HTTPMethod = @"PUT";
    request.HTTPBody = json;
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:request];
    NSMutableString *msg = [[NSMutableString alloc] init];
    connection.completionBlock = ^(id obj, NSError *err) {
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:obj options:0 error:nil];
        NSLog(@"%@", d);
    };
    [connection start];
}

- (void)write {
    if (self.pendingChanges.count == 0)
        return;
    NSLog(@"Writing changes: %@", self.pendingChanges);
    NSData *json = [NSJSONSerialization dataWithJSONObject:[self.pendingChanges copy] options:0 error:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = self.URL;
    request.HTTPMethod = @"PUT";
    request.HTTPBody = json;
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:request];
    connection.jsonRootObject = self;
    NSMutableString *msg = [[NSMutableString alloc] init];
    connection.completionBlock = ^(id obj, NSError *err) {

    };
    [connection start];
    [self.pendingChanges removeAllObjects];
}

- (void)writeAll {
    // subclasses should put all properties into the pending changes dictionary then call [super writeAll];
    [self write];
}

#pragma mark - DSJSONSerializable

// TODO: Make this call a delegate message

- (void)readFromJSONDictionary:(id)d {
    
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
            }
        }
        if (errorFound == NO) {
            _pendingChanges = [NSMutableDictionary dictionary];
        }
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        // for subclasses
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    // for subclasses
}


@end
