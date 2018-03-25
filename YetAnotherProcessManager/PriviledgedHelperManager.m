//
//  PriviledgedHelperManager.m
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/25/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

// https://developer.apple.com/library/content/samplecode/EvenBetterAuthorizationSample

#import "PriviledgedHelperManager.h"

@implementation PriviledgedHelperManager

- (instancetype)init {
    if(self = [super init]) {
        OSStatus                    err;
        AuthorizationExternalForm   extForm;
        
        // Create our connection to the authorization system.
        //
        // If we can't create an authorization reference then the app is not going to be able
        // to do anything requiring authorization.  Generally this only happens when you launch
        // the app in some wacky, and typically unsupported, way.  In the debug build we flag that
        // with an assert.  In the release build we continue with self->_authRef as NULL, which will
        // cause all authorized operations to fail.
        
        err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
        if (err == errAuthorizationSuccess) {
            err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
        }
        if (err == errAuthorizationSuccess) {
            self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
        }
        assert(err == errAuthorizationSuccess);
        
        // If we successfully connected to Authorization Services, add definitions for our default
        // rights (unless they're already in the database).
        
        if (self->_authRef) {
            [Common setupAuthorizationRights:self->_authRef];
        }
    }
    return self;
}

- (BOOL)installHelper {
    Boolean             success;
    CFErrorRef          error;
    
    // TODO: move helper bindleId to Info.plist
    success = SMJobBless(
                         kSMDomainSystemLaunchd,
                         CFSTR("com.kukushechkin.YetAnotherProcessManager.HelperTool"),
                         self->_authRef,
                         &error
                         );
    
    if (success) {
        NSLog(@"success");
    } else {
        NSLog(@"error: %@", error);
        CFRelease(error);
    }
    
    return success;
}

- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        self.helperToolConnection.invalidationHandler = ^{
            // If the connection gets invalidated then, on the main thread, nil out our
            // reference to it.  This ensures that we attempt to rebuild it the next time around.
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                NSLog(@"connection invalidated");
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
// Connects to the helper tool and then executes the supplied command block on the
// main thread, passing it an error indicating if the connection was successful.
{
    assert([NSThread isMainThread]);
    
    // Ensure that there's a helper tool connection in place.
    
    [self connectToHelperTool];
    
    // Run the command block.  Note that we never error in this case because, if there is
    // an error connecting to the helper tool, it will be delivered to the error handler
    // passed to -remoteObjectProxyWithErrorHandler:.  However, I maintain the possibility
    // of an error here to allow for future expansion.
    
    commandBlock(nil);
}

- (void)killProcessWithPid:(pid_t)pid
{
    [self connectAndExecuteCommandBlock:^(NSError * connectError) {
        if (connectError != nil) {
            NSLog(@"%@", connectError);
        } else {
            [[self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
                NSLog(@"%@", proxyError);
            }] killProcessWithPid:pid];
        }
    }];
}

@end
