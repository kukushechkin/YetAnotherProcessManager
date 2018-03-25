//
//  ProcessManager.m
//  YetAnotherProcessManager
//
//  Created by Vladimir Kukushkin on 3/20/18.
//  Copyright © 2018 kukushechkin. All rights reserved.
//

// https://developer.apple.com/library/content/technotes/tn2050/_index.html

#import "ProcessManager.h"
#import "YetAnotherProcessManager-Swift.h"

#include <vector>

@implementation ProcessManager

- (instancetype)init {
    if(self = [super init]) {
        priviledgedHelperManager = [PriviledgedHelperManager new];
    }
    return self;
}

- (NSArray*)processes {
    
    // NSWrokspace could be used for user processes, even in sandbox
    // For all processes proc_listallpids
    
    // proc_listallpids usage googled
    std::vector<pid_t> pids;
    size_t nproc = proc_listallpids(0, 0);
    if (nproc != -1) {
        pids.resize(nproc);
        if (nproc > 0) {
            nproc = proc_listallpids(&pids[0], pids.size() * sizeof(pid_t));
            pids.resize(nproc);
        }
    }
    
    // TODO: cache processes list with std::vector
    NSMutableArray* newProccessesList = [NSMutableArray new];
    
    for(auto& pid : pids) {
        Process * newProcess = nil;
        
        // https://stackoverflow.com/questions/46070563/how-can-i-get-all-process-name-in-os-x-programmatically-not-just-app-processes
        struct proc_bsdshortinfo bsdshortinfo;
        int writtenSize;
        writtenSize = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, &bsdshortinfo, sizeof(bsdshortinfo));
        
        if (writtenSize != (int)sizeof(bsdshortinfo)) {
            newProcess = [[Process alloc] initWithPid:pid];
        }
        else {
            NSString * processName = [NSString stringWithUTF8String:bsdshortinfo.pbsi_comm];
            newProcess = [[Process alloc] initWithPid:pid
                                                 name:processName
                                               andUid:bsdshortinfo.pbsi_uid];
        }
        
        [newProccessesList addObject:newProcess];
    }
    
    // TODO: create NSArray right here from vector
    return newProccessesList;
}

- (void)killProcessWithPid:(pid_t)pid {
    // TODO: check if process kill actually requires priviledge escalation

    // try install priviledged helper
    [priviledgedHelperManager installHelper];
    
    [priviledgedHelperManager killProcessWithPid:pid];
}

@end
