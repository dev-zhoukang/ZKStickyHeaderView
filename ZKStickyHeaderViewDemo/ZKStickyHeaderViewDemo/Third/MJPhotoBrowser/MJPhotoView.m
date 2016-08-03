//
//  MJZoomingScrollView.m
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import "MJPhotoView.h"
#import "MJPhoto.h"
#import "MJPhotoLoadingView.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

@interface MJPhotoView ()

@property (nonatomic, assign) BOOL doubleTap;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) MJPhotoLoadingView *photoLoadingView;
//@property (nonatomic, strong) UIImage *scaledCaptureImage;

@end

static CGFloat const kAnimationDuration = 0.5f;

@implementation MJPhotoView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.clipsToBounds = YES;
    // 图片
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    [self addSubview:_imageView];
    
    // 进度条
    _photoLoadingView = [[MJPhotoLoadingView alloc] init];
    
    // 属性
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 监听点击
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.delaysTouchesBegan = YES;
    singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
}

#pragma mark - photoSetter
- (void)setPhoto:(MJPhoto *)photo
{
    _photo = photo;
    [self showImage];
}

#pragma mark 显示图片
- (void)showImage
{
    self.userInteractionEnabled = NO;
    
    if (_photo.firstShow) { // 首次显示
        _imageView.image = _photo.placeholder; // 占位图片
        _photo.srcImageView.image = nil;
        
        // 不是gif，就马上开始下载
        if (![_photo.url.absoluteString hasSuffix:@"gif"]) {
            __weak MJPhotoView *photoView = self;
            __weak MJPhoto *photo = _photo;
            
            [_imageView sd_setImageWithURL:_photo.url placeholderImage:_photo.placeholder options:SDWebImageRetryFailed|SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                photo.image = image;
                
                // 调整frame参数
                [photoView adjustFrame];
            }];
        }
    } else {
        [self photoStartLoad];
    }

    // 调整frame参数
    [self adjustFrame];
}

#pragma mark 开始加载图片
- (void)photoStartLoad
{
    if (_photo.image) {
        self.scrollEnabled = YES;
        _imageView.image = _photo.image;
    } else {
        self.scrollEnabled = NO;
        // 直接显示进度条
        [_photoLoadingView showLoading];
        [self addSubview:_photoLoadingView];
        
        __unsafe_unretained MJPhotoView *photoView = self;
        __unsafe_unretained MJPhotoLoadingView *loading = _photoLoadingView;
        [_imageView sd_setImageWithURL:_photo.url placeholderImage:_photo.placeholder options:SDWebImageRetryFailed|SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            if (receivedSize > kMinProgress) {
                loading.progress = (float)receivedSize/expectedSize;
            }
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [photoView photoDidFinishLoadWithImage:image];
        }];
    }
}

#pragma mark 加载完毕
- (void)photoDidFinishLoadWithImage:(UIImage *)image
{
    if (image) {
        self.scrollEnabled = YES;
        _photo.image = image;
        [_photoLoadingView removeFromSuperview];
        
        if ([self.photoViewDelegate respondsToSelector:@selector(photoViewImageFinishLoad:)]) {
            [self.photoViewDelegate photoViewImageFinishLoad:self];
        }
    } else {
        [self addSubview:_photoLoadingView];
        [_photoLoadingView showFailure];
    }
    
    // 设置缩放比例
    [self adjustFrame];
}
#pragma mark 调整frame
- (void)adjustFrame
{
	if (_imageView.image == nil) return;
    
    // 基本尺寸参数
    CGSize boundsSize = self.bounds.size;
    CGFloat boundsWidth = boundsSize.width;
    CGFloat boundsHeight = boundsSize.height;
    
    CGSize imageSize = _imageView.image.size;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
	
	// 设置伸缩比例
    CGFloat minScale = boundsWidth / imageWidth;
	if (minScale > 1) {
		minScale = 1.0;
	}
	CGFloat maxScale = 3.0;
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
	}
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
	self.zoomScale = minScale;
    
    CGRect imageFrame = CGRectMake(0, 0, boundsWidth, imageHeight * boundsWidth / imageWidth);
    // 内容尺寸
    self.contentSize = CGSizeMake(0, imageFrame.size.height);
    
    // y值
    if (imageFrame.size.height < boundsHeight) {
        imageFrame.origin.y = floorf((boundsHeight - imageFrame.size.height) / 2.0);
	} else {
        imageFrame.origin.y = 0;
	}
    
    if (_photo.firstShow) { // 第一次显示的图片
        _photo.firstShow = NO; // 已经显示过了
        _imageView.frame = [_photo.srcImageView convertRect:_photo.srcImageView.bounds toView:nil];
        
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             _imageView.frame = imageFrame;
                             
                         } completion:^(BOOL finished) {
                             // 设置底部的小图片
                             _photo.srcImageView.image = _photo.placeholder;
                             [self photoStartLoad];
                             self.userInteractionEnabled = YES;
                         }];
    }
    else {
        _imageView.frame = imageFrame;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAnimationDuration-1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.userInteractionEnabled = YES;
        });
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _imageView;
}

/** 缩放后调整视图位置 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIImageView *zoomView = [[scrollView subviews] firstObject];
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width)/2 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height)/2 : 0.0;
    zoomView.center = CGPointMake(scrollView.contentSize.width/2 + offsetX, scrollView.contentSize.height/2 + offsetY);
}

#pragma mark - 手势处理
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    _doubleTap = NO;
    [self performSelector:@selector(hide) withObject:nil afterDelay:0.2];
}

- (void)hide
{
    if (_doubleTap) return;
    
    //_scaledCaptureImage = [self captureWithView:_imageView];
    
    // 移除进度条
    [_photoLoadingView removeFromSuperview];
    
    // 清空底部的小图
    //_photo.srcImageView.image = nil;
    
    NSTimeInterval duration = 0.12;
//    if (_photo.srcImageView.clipsToBounds) {
//        [self performSelector:@selector(reset) withObject:nil afterDelay:duration];
//    }
    
    CGRect originalRect = [_photo.srcImageView convertRect:_photo.srcImageView.bounds toView:nil];
    
    [UIView animateWithDuration:duration + 0.15 animations:^{
        _imageView.frame = (CGRect){self.contentOffset.x+originalRect.origin.x,
                                    self.contentOffset.y+originalRect.origin.y,
                                    originalRect.size};
        // gif图片仅显示第0张
        if (_imageView.image.images) {
            _imageView.image = _imageView.image.images[0];
        }
        
        // 通知代理
        if ([self.photoViewDelegate respondsToSelector:@selector(photoViewSingleTap:)]) {
            [self.photoViewDelegate photoViewSingleTap:self];
        }
    } completion:^(BOOL finished) {
        // 设置底部的小图片
        _photo.srcImageView.image = _photo.placeholder;
        
        // 通知代理
        if ([self.photoViewDelegate respondsToSelector:@selector(photoViewDidEndZoom:)]) {
            [self.photoViewDelegate photoViewDidEndZoom:self];
        }
    }];
}

- (void)reset
{
    //_imageView.image = _scaledCaptureImage;
    //_imageView.contentMode = UIViewContentModeScaleAspectFill;
}

//- (UIImage*)imageWithImage:(UIImage*)image
//              scaledToSize:(CGSize)newSize;
//{
//    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
//    [image drawInRect:(CGRect){CGPointZero,newSize}];
//    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    return newImage;
//}
//
//- (UIImage *)captureWithView:(UIView *)view
//{
//    CGFloat mainScale = [UIScreen mainScreen].scale;
//    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
//    CGSize viewSize = view.bounds.size;
//    CGSize srcImageSize = _photo.srcImageView.bounds.size;
//    
//    UIGraphicsBeginImageContextWithOptions(viewSize, YES, mainScale);
//    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *originalImage = UIGraphicsGetImageFromCurrentImageContext();
//    
//    CGImageRef captureImageRef;
//    if (viewSize.width/viewSize.height <= (screenWidth/200.f)) {
//        
//        CGFloat captureImageW = viewSize.width;
//        CGFloat captureImageH = captureImageW * (srcImageSize.height/srcImageSize.width);
//        captureImageRef =
//        CGImageCreateWithImageInRect(originalImage.CGImage, CGRectMake(0,
//                                                                       (viewSize.height-captureImageH)*0.5*mainScale,
//                                                                       captureImageW*mainScale,
//                                                                       captureImageH*mainScale));
//    }
//    else {
//        CGFloat captureImageH = viewSize.height;
//        CGFloat captureImageW = captureImageH * (srcImageSize.width/srcImageSize.height);
//        captureImageRef =
//        CGImageCreateWithImageInRect(originalImage.CGImage, CGRectMake((viewSize.width-captureImageW)*0.5*mainScale,
//                                                                       0,
//                                                                       captureImageW*mainScale,
//                                                                       captureImageH*mainScale));
//    }
//    
//    UIImage *captureImage = [UIImage imageWithCGImage:captureImageRef];
//    
//    UIImage *scaledImage = [self imageWithImage:captureImage scaledToSize:CGSizeMake(srcImageSize.width/mainScale, srcImageSize.height/mainScale)];
//    
//    CGImageRelease(captureImageRef);
//    
//    UIGraphicsEndImageContext();
//    
//    return scaledImage;
//}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    _doubleTap = YES;
    
    CGPoint touchPoint = [tap locationInView:self];
	if (self.zoomScale == self.maximumZoomScale) {
		[self setZoomScale:self.minimumZoomScale animated:YES];
	} else {
        CGPoint covertedPoint = [self convertPoint:touchPoint toView:_imageView];
        [self zoomToRect:(CGRect){covertedPoint, 1.f, 1.f} animated:YES];
	}
}

/** 根据手指位置计算zoomRect */
- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)touchPoint
{
    CGRect zoomRect;
    
    zoomRect.size.height =  _imageView.frame.size.height / scale;;
    zoomRect.size.width  =  _imageView.frame.size.width / scale;;
    
    touchPoint = [self convertPoint:touchPoint toView:_imageView];
    
    zoomRect.origin.x    = touchPoint.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = touchPoint.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)dealloc
{
    // 取消请求
    [_imageView sd_setImageWithURL:[NSURL URLWithString:@"file:///abc"]];
}
@end