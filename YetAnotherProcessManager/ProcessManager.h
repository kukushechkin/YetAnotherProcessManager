//
//  ProcessManager.h
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PriviledgedHelperManager.h"
#include <libproc.h>

@interface ProcessManager : NSObject
{
    PriviledgedHelperManager * priviledgedHelperManager;
}

@property (readonly) NSArray* processes;

- (void)killProcessWithPid:(pid_t)pid;

@end
