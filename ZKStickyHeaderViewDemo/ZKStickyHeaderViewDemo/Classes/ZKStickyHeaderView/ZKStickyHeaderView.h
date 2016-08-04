//
//  ZKStickyHeaderView.h
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZKStickyHeaderView;

#define HEADER_HEIGHT       200.0f
#define HEADER_INIT_FRAME   CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, HEADER_HEIGHT)

@protocol ZKStickyHeaderViewDelegate <NSObject>
@optional
- (void)stickyHeaderViewDidTap:(ZKStickyHeaderView *)stickyView;
@end

@interface ZKStickyHeaderView : UIView

@property (nonatomic, weak) id <ZKStickyHeaderViewDelegate> delegate;

+ (instancetype)headerViewWithImageNames:(NSArray <NSString *> *)imageNames initFrame:(CGRect)initFrame;

/** 在`scrollViewDidScroll`中实现 */
- (void)updateFrameWhenScroll;

@end
