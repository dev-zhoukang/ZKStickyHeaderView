//
//  ZKStickyHeaderView.h
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ZKStickyHeaderView;

@protocol ZKStickyHeaderViewDelegate <NSObject>
@optional
- (void)stickyHeaderViewDidTap:(ZKStickyHeaderView *)stickyView;
@end

@interface ZKStickyHeaderView : UIView

@property (nonatomic, weak) id <ZKStickyHeaderViewDelegate> delegate;
@property (nonatomic, assign) BOOL isExpanded;

- (void)updateFrame:(CGRect)rect;

@end
