//
//  MJPhotoLoadingView.h
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MJPhotoBrowser, MJPhoto;

extern CGFloat const kMinProgress;

@interface MJPhotoLoadingView : UIView

@property (nonatomic) CGFloat progress;

- (void)showLoading;
- (void)showFailure;

@end