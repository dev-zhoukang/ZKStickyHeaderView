//
//  MJPhotoBrowser.m
//
//  Created by ZK on 16/7/19.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"
#import "SDWebImageManager+MJ.h"
#import "MJPhotoView.h"
#import "MJPhotoToolbar.h"

#define PhotoViewIndex(photoView)   ([photoView tag] - kPhotoViewTagOffset)
#define KeyWindow                    [UIApplication sharedApplication].keyWindow

@interface MJPhotoBrowser () <MJPhotoViewDelegate>

@property (nonatomic, strong) UIScrollView   *photoScrollView;
@property (nonatomic, strong) NSMutableSet   *visiblePhotoViews;
@property (nonatomic, strong) NSMutableSet   *reusablePhotoViews;
@property (nonatomic, strong) MJPhotoToolbar *toolbar;
@property (nonatomic, assign) BOOL statusBarHiddenInited; //!< 一开始的状态栏
@property (nonatomic, strong) NSArray <MJPhoto *> *photos;//!< 存放所有图片
@property (nonatomic, assign) NSUInteger          currentPhotoIndex;//!< 当前展示的图片索引

@end

static CGFloat const kPadding            = 10.f;
static CGFloat const kPhotoViewTagOffset = 1000.f;

@implementation MJPhotoBrowser

#pragma mark - Lifecycle
- (void)loadView
{
    [super loadView];
    _statusBarHiddenInited = [UIApplication sharedApplication].isStatusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    self.view = [[UIView alloc] init];
    self.view.frame = [UIScreen mainScreen].bounds;
	self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupScrollView];
    
    [self setupToolbar];
}

- (void)show
{
    [KeyWindow addSubview:self.view];
    [KeyWindow.rootViewController addChildViewController:self];

    if (_currentPhotoIndex == 0) {
        [self showPhotos];
    }
}

#pragma mark - 私有方法
#pragma mark 创建工具条
- (void)setupToolbar
{
    CGFloat barHeight = 44.f;
    CGFloat barY = self.view.frame.size.height - barHeight;
    _toolbar = [[MJPhotoToolbar alloc] init];
    _toolbar.frame = CGRectMake(0, barY, self.view.frame.size.width, barHeight);
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _toolbar.photos = _photos;
    [self.view addSubview:_toolbar];
    
    [self updateTollbarState];
}

#pragma mark 创建UIScrollView
- (void)setupScrollView
{
    CGRect frame = self.view.bounds;
    frame.origin.x   -= kPadding;
    frame.size.width += (2 * kPadding);
	_photoScrollView = [[UIScrollView alloc] initWithFrame:frame];
    
	_photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_photoScrollView.pagingEnabled = YES;
	_photoScrollView.delegate = self;
	_photoScrollView.showsHorizontalScrollIndicator = NO;
	_photoScrollView.showsVerticalScrollIndicator = NO;
	_photoScrollView.backgroundColor = [UIColor clearColor];
    _photoScrollView.contentSize = CGSizeMake(frame.size.width * _photos.count, 0);
	[self.view addSubview:_photoScrollView];
    _photoScrollView.contentOffset = CGPointMake(_currentPhotoIndex * frame.size.width, 0);
}

#pragma mark - 公共方法
- (instancetype)initWithPhotos:(NSArray <MJPhoto *> *)photos currentPhotoIndex:(NSUInteger)index
{
    NSEnumerator *subEnum = [KeyWindow.rootViewController.childViewControllers reverseObjectEnumerator];
    for (UIViewController *vc in subEnum) {
        if ([vc isKindOfClass:[self class]]) {
            return nil;
        }
    }
    
    if (self = [super init]) {
        
        _photos = photos;
        _currentPhotoIndex = index;
        
        if (photos.count > 1) {
            _visiblePhotoViews  = [NSMutableSet set];
            _reusablePhotoViews = [NSMutableSet set];
        }
        
        for (NSInteger i = 0; i<photos.count; i++) {
            MJPhoto *photo = photos[i];
            photo.index = i;
            photo.firstShow = i == index;
        }
        
        if ([self isViewLoaded]) {
            _photoScrollView.contentOffset = CGPointMake(_currentPhotoIndex * _photoScrollView.frame.size.width, 0);
            
            // 显示所有的相片
            [self showPhotos];
        }
    }
    return self;
}

#pragma mark - MJPhotoView代理
- (void)photoViewSingleTap:(MJPhotoView *)photoView
{
    [UIApplication sharedApplication].statusBarHidden = _statusBarHiddenInited;
    self.view.backgroundColor = [UIColor clearColor];
    
    // 移除工具条
    [_toolbar removeFromSuperview];
}

- (void)photoViewDidEndZoom:(MJPhotoView *)photoView
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    if ([self.delegate respondsToSelector:@selector(photoBrowserDidEndShowing:)]) {
        [self.delegate photoBrowserDidEndShowing:self];
    }
}

- (void)photoViewImageFinishLoad:(MJPhotoView *)photoView
{
    _toolbar.currentPhotoIndex = _currentPhotoIndex;
}

#pragma mark 显示照片
- (void)showPhotos
{
    // 只有一张图片
    if (_photos.count == 1) {
        [self showPhotoViewAtIndex:0];
        return;
    }
    
    CGRect visibleBounds = _photoScrollView.bounds;
	NSInteger firstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+kPadding*2) / CGRectGetWidth(visibleBounds));
	NSInteger lastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-kPadding*2-1) / CGRectGetWidth(visibleBounds));
    if (firstIndex < 0) firstIndex = 0;
    if (firstIndex >= _photos.count) firstIndex = _photos.count - 1;
    if (lastIndex < 0) lastIndex = 0;
    if (lastIndex >= _photos.count) lastIndex = _photos.count - 1;
	
	// 回收不再显示的ImageView
    NSInteger photoViewIndex;
	for (MJPhotoView *photoView in _visiblePhotoViews) {
        photoViewIndex = PhotoViewIndex(photoView);
		if (photoViewIndex < firstIndex || photoViewIndex > lastIndex) {
			[_reusablePhotoViews addObject:photoView];
			[photoView removeFromSuperview];
		}
	}
    
	[_visiblePhotoViews minusSet:_reusablePhotoViews];
    while (_reusablePhotoViews.count > 2) {
        [_reusablePhotoViews removeObject:[_reusablePhotoViews anyObject]];
    }
	
	for (NSUInteger index = firstIndex; index <= lastIndex; index++) {
		if (![self isShowingPhotoViewAtIndex:index]) {
			[self showPhotoViewAtIndex:index];
		}
	}
}

#pragma mark 显示一个图片view
- (void)showPhotoViewAtIndex:(NSUInteger)index
{
    MJPhotoView *photoView = [self dequeueReusablePhotoView];
    if (!photoView) { // 添加新的图片view
        photoView = [[MJPhotoView alloc] init];
        NSLog(@"photoView地址:%p", photoView);
        photoView.photoViewDelegate = self;
    }
    
    // 调整当期页的frame
    CGRect bounds = _photoScrollView.bounds;
    CGRect photoViewFrame = bounds;
    photoViewFrame.size.width -= (2 * kPadding);
    photoViewFrame.origin.x = (bounds.size.width * index) + kPadding;
    photoView.tag = kPhotoViewTagOffset + index;
    
    MJPhoto *photo = _photos[index];
    photoView.frame = photoViewFrame;
    photoView.photo = photo;
    
    [_visiblePhotoViews addObject:photoView];
    [_photoScrollView addSubview:photoView];
    
    [self loadImageNearIndex:index];
}

#pragma mark 加载index附近的图片
- (void)loadImageNearIndex:(NSUInteger)index
{
    if (index > 0) {
        MJPhoto *photo = _photos[index - 1];
        [SDWebImageManager downloadWithURL:photo.url];
    }
    
    if (index < _photos.count - 1) {
        MJPhoto *photo = _photos[index + 1];
        [SDWebImageManager downloadWithURL:photo.url];
    }
}

#pragma mark index这页是否正在显示
- (BOOL)isShowingPhotoViewAtIndex:(NSUInteger)index {
	for (MJPhotoView *photoView in _visiblePhotoViews) {
		if (PhotoViewIndex(photoView) == index) {
           return YES;
        }
    }
	return  NO;
}

#pragma mark 循环利用某个view
- (MJPhotoView *)dequeueReusablePhotoView
{
    MJPhotoView *photoView = [_reusablePhotoViews anyObject];
	if (photoView) {
		[_reusablePhotoViews removeObject:photoView];
	}
	return photoView;
}

#pragma mark 更新toolbar状态
- (void)updateTollbarState
{
    _currentPhotoIndex = _photoScrollView.contentOffset.x / _photoScrollView.frame.size.width+0.5;
    _toolbar.currentPhotoIndex = _currentPhotoIndex;
}

#pragma mark - UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self showPhotos];
    [self updateTollbarState];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(photoBrowser:didChangedToPageAtIndex:)]) {
        [_delegate photoBrowser:self didChangedToPageAtIndex:_currentPhotoIndex];
    }
}

@end