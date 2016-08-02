//
//  MJPhotoBrowser.h
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MJPhoto.h"
@class MJPhotoBrowser;

@protocol MJPhotoBrowserDelegate <NSObject>
@optional
/** 切换到某一页图片 */
- (void)photoBrowser:(MJPhotoBrowser *)photoBrowser didChangedToPageAtIndex:(NSUInteger)index;
@end

@interface MJPhotoBrowser : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) id<MJPhotoBrowserDelegate> delegate;

/** 初始化方法, 一定要实现 */
- (instancetype)initWithPhotos:(NSArray <MJPhoto *> *)photos currentPhotoIndex:(NSUInteger)index;

- (void)show;

@end
