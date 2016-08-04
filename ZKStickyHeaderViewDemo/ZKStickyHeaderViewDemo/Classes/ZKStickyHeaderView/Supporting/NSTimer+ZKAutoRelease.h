//
//  NSTimer+ZKAutoRelease.h
//  HappyIn
//
//  Created by ZK on 16/5/9.
//  Copyright © 2016年 MaRuJun. All rights reserved.
// 注意: NSTimer与target相互引用, 形成保留环导致内存泄露.

#import <Foundation/Foundation.h>

@interface NSTimer (ZKAutoRelease)

+ (NSTimer *)zk_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void(^)())block repeates:(BOOL)repeates;

@end
