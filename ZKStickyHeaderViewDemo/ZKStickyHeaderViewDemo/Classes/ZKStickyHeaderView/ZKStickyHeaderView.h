//
//  ZKStickyHeaderView.h
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZKStickyHeaderViewDelegate <NSObject>
@optional
- (void)toggleHeaderViewFrame;
@end

@interface ZKStickyHeaderView : UIView

@property (nonatomic, weak) id <ZKStickyHeaderViewDelegate> delegate;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) BOOL pageControlUsed;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

- (void)updateFrame:(CGRect)rect;

@end
