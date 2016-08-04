//
//  NSTimer+ZKAutoRelease.m
//  HappyIn
//
//  Created by ZK on 16/5/9.
//  Copyright © 2016年 MaRuJun. All rights reserved.
//

#import "NSTimer+ZKAutoRelease.h"

@implementation NSTimer (ZKAutoRelease)

+ (NSTimer *)zk_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)())block repeates:(BOOL)repeates
{
    return [self scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(zk_blockInvoke:)
                                       userInfo:[block copy]
                                        repeats:repeates];
}

+ (void)zk_blockInvoke:(NSTimer *)timer
{
    void (^block) () = timer.userInfo;
    !block?:block();
}

@end
