//
//  PriviledgedHelperManager.h
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/25/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelperTool.h"
#import "Common.h"
#include <ServiceManagement/ServiceManagement.h>

@interface PriviledgedHelperManager : NSObject
{
    AuthorizationRef    _authRef;
}

@property (atomic, copy,   readwrite) NSData *          authorization;
@property (atomic, strong, readwrite) NSXPCConnection * helperToolConnection;

- (BOOL)installHelper;
- (void)connectToHelperTool;
- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock;

- (void)killProcessWithPid:(pid_t)pid;

@end
