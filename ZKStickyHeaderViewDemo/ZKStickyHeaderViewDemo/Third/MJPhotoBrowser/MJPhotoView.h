//
//  MJZoomingScrollView.h
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MJPhotoBrowser, MJPhoto, MJPhotoView;

@protocol MJPhotoViewDelegate <NSObject>

- (void)photoViewImageFinishLoad:(MJPhotoView *)photoView;
- (void)photoViewSingleTap:(MJPhotoView *)photoView;
- (void)photoViewDidEndZoom:(MJPhotoView *)photoView;

@end

@interface MJPhotoView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) MJPhoto *photo;
@property (nonatomic, weak) id<MJPhotoViewDelegate> photoViewDelegate;

@end