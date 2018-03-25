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
#include <algorithm>
#include <iterator>

// [FIXME] oops, std::set_difference only works with operator<
bool myfunction (pid_t i, pid_t j) { return (i < j); }

@implementation ProcessManager

std::vector<pid_t> pidsSnapshot;
// NSMutableDictionary<NSNumber*, Process*> * processesSnapshot;
NSMutableArray<Process*> * processesSnapshot;
dispatch_source_t dispatchSource;

- (instancetype)init {
    if(self = [super init]) {
        priviledgedHelperManager = [PriviledgedHelperManager new];
        // processesSnapshot = [NSMutableDictionary new];
        processesSnapshot = [NSMutableArray new];
        
        [self setupProcessesSnapshot];
    }
    return self;
}

- (void)setupProcessesSnapshot {
    dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    double interval = 0.5;
    dispatch_source_set_timer(dispatchSource,
                              dispatch_time(DISPATCH_TIME_NOW, 0),
                              interval * NSEC_PER_SEC,
                              0);
    dispatch_source_set_event_handler(dispatchSource, ^{
        [self enumProcesses];
    });
    dispatch_resume(dispatchSource);
}

- (void)enumProcesses {
    std::vector<pid_t> newPids;
    size_t nproc = proc_listallpids(0, 0);
    if (nproc != -1) {
        newPids.resize(nproc);
        if (nproc > 0) {
            nproc = proc_listallpids(&newPids[0], newPids.size() * sizeof(pid_t));
            newPids.resize(nproc);
        }
    }
    
    std::sort(newPids.begin(), newPids.end(), myfunction);
    std::sort(pidsSnapshot.begin(), pidsSnapshot.end(), myfunction);
    
    @synchronized(processesSnapshot) {
        std::vector<pid_t> exitedPids;
        std::set_difference(pidsSnapshot.begin(), pidsSnapshot.end(),
                            newPids.begin(), newPids.end(),
                            std::inserter(exitedPids, exitedPids.begin()));
        
        std::vector<pid_t> launchedPids;
        std::set_difference(newPids.begin(), newPids.end(),
                            pidsSnapshot.begin(), pidsSnapshot.end(),
                            std::inserter(launchedPids, launchedPids.begin()));
        
        pidsSnapshot.erase(std::remove_if(std::begin(pidsSnapshot), std::end(pidsSnapshot), [&exitedPids](const auto& e) {
            return std::find(std::cbegin(exitedPids), std::cend(exitedPids), e) != std::end(exitedPids);
        }), std::end(pidsSnapshot));
        
        pidsSnapshot.insert(std::end(pidsSnapshot), std::begin(launchedPids), std::end(launchedPids));
        
        NSArray * imutableCopy = [processesSnapshot copy];
        for(Process * proc in imutableCopy) {
            if(std::find(exitedPids.begin(), exitedPids.end(), proc.pid) != exitedPids.end()) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:[imutableCopy indexOfObject:proc]];
                    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"processes"];
                    [processesSnapshot removeObject:proc];
                    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"processes"];
                });
            }
        }
        
        for(auto& pid : launchedPids) {
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

            dispatch_async(dispatch_get_main_queue(), ^(void){
                NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:processesSnapshot.count];
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"processes"];
                [processesSnapshot insertObject:newProcess atIndex:processesSnapshot.count];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexSet forKey:@"processes"];
            });
        }
    }
}

- (NSArray*)processes {
    return processesSnapshot;
}

- (void)killProcessWithPid:(pid_t)pid {
    // TODO: remove process from the list right now, do not wait for enumeration
    // TODO: check if process kill actually requires priviledge escalation

    // try install priviledged helper
    [priviledgedHelperManager installHelper];
    
    [priviledgedHelperManager killProcessWithPid:pid];
}

@end
