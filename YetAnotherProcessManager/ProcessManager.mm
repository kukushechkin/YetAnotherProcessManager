//
//  ProcessManager.m
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

#import "ProcessManager.h"

@implementation ProcessManager

- (instancetype)init
{
    if(self = [super init]) {
        //
    }
    return self;
}

- (NSArray*)processes
{
    // TODO: cache
    NSArray* newProccessesList = @[[Process new], [Process new], [Process new]];
    return newProccessesList;
}

@end
