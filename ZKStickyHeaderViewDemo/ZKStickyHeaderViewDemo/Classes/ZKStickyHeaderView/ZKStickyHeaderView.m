//
//  ZKStickyHeaderView.m
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import "ZKStickyHeaderView.h"
#import "UIImageView+WebCache.h"
#import "MJPhotoBrowser.h"
#import "NSTimer+ZKAutoRelease.h"

#define  SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width

@interface ZKStickyHeaderView() <UIScrollViewDelegate, MJPhotoBrowserDelegate>

@property (nonatomic, strong) NSArray <NSString *> *imageNames;
@property (nonatomic, assign) BOOL                 pageControlUsed;
@property (nonatomic, strong) UIScrollView         *scrollView;
@property (nonatomic, strong) UIPageControl        *pageControl;
@property (nonatomic, strong) NSTimer              *timer;

@end

static CGFloat const kPageControlBottomSpace = 15.0f;

@implementation ZKStickyHeaderView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.scrollView];
    }
    return self;
}

+ (instancetype)headerViewWithImageNames:(NSArray<NSString *> *)imageNames initFrame:(CGRect)initFrame {
    ZKStickyHeaderView *headerView = [[ZKStickyHeaderView alloc] initWithFrame:initFrame];
    headerView.imageNames = imageNames;
    return headerView;
}

#pragma mark - Timer
- (void)handleTimer {
    if (_imageNames.count == 1) {
        [self removeTimer];
        return;
    }
    
    CGFloat width = self.scrollView.frame.size.width;
    
    CGFloat offsetX = (self.pageControl.currentPage + 1) * width + width;
    CGPoint offset = CGPointMake(offsetX, 0);
    [self.scrollView setContentOffset:offset animated:YES];
}

- (void)addTimer {
    __weak typeof(self) weakSelf = self;
    _timer = [NSTimer zk_scheduledTimerWithTimeInterval:2 block:^{
        [weakSelf handleTimer];
    } repeates:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    [_timer invalidate];
    self.timer = nil;
}

#pragma mark - Setter
- (void)setImageNames:(NSArray<NSString *> *)imageNames {
    _imageNames = imageNames;
    if ([_imageNames count] > 1) {
        [self addSubview:self.pageControl];
    }
    [self setupImageViews];
    [self addTimer];
}

- (void)setupImageViews {
    NSUInteger imageCount = _imageNames.count;
    CGFloat width = self.scrollView.bounds.size.width;
    
    for (NSInteger i = 0; i < _imageNames.count+2; i ++) {
        UIImageView *imageView = [[UIImageView alloc]
                                  initWithFrame:(CGRect){width*i, 0, self.scrollView.frame.size}];
        [self.scrollView addSubview:imageView];
        
        imageView.userInteractionEnabled = YES;
        [imageView setContentMode:UIViewContentModeScaleAspectFill];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [imageView.layer setMasksToBounds:YES];
        
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(handleTap:)]];
        
        NSString *imageNameStr = nil;
        if (i == 0) {
            imageNameStr = _imageNames[imageCount-1];
            imageView.tag = imageCount-1;
        }
        else if (i == imageCount+1) {
            imageNameStr = _imageNames[0];
            imageView.tag = 0;
        }
        else {
            imageNameStr = _imageNames[i-1];
            imageView.tag = i-1;
        }
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner setCenter:CGPointMake(imageView.center.x, imageView.center.y)];
        [spinner startAnimating];
        [imageView addSubview:spinner];
        
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageNameStr] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [spinner removeFromSuperview];
        }];
    }
    
    self.scrollView.contentSize = CGSizeMake(width*(imageCount+2), HEADER_HEIGHT);
    self.scrollView.contentOffset = CGPointMake(width, 0);
}

#pragma mark - Private Mehods

- (void)updateFrameWhenScroll {
    float delta = 0.0f;
    CGRect rect = HEADER_INIT_FRAME;
    
    UITableView *tableView = [self superTableView];
    
    if (tableView.contentOffset.y < 0.0f) {
        delta = fabs(MIN(0.0f, tableView.contentOffset.y));
    }
    
    rect.origin.y    -= delta;
    rect.size.height += delta;
    
    [self updateFrame:rect];
}

- (void)updateFrame:(CGRect)rect {
    self.frame = rect;
    _scrollView.frame = rect;
    
    float y = self.frame.size.height + _scrollView.frame.origin.y - kPageControlBottomSpace;
    _pageControl.frame = CGRectMake(0.0f, y, self.frame.size.width, kPageControlBottomSpace);
}

- (UITableView *)superTableView {
   id view = [self superview];
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = [view superview];
    }
    return (UITableView *)view;
}

#pragma mark - UITapGestureRecognizer

- (void)handleTap:(UITapGestureRecognizer *)tap {
    [self removeTimer];
    if ([_delegate respondsToSelector:@selector(stickyHeaderViewDidTap:)]) {
        [_delegate stickyHeaderViewDidTap:self];
    }
    [self showPhotoBrowserWithTap:tap];
}

- (void)showPhotoBrowserWithTap:(UITapGestureRecognizer *)tap {
    NSInteger count = _imageNames.count;
    NSMutableArray <MJPhoto *> *photos = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i<count; i++) {
        NSString *url = _imageNames[i];
        MJPhoto *photo = [[MJPhoto alloc] init];
        photo.url = [NSURL URLWithString:url];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"class == %@", [UIImageView class]];
        NSArray *fillteredArray = [_scrollView.subviews filteredArrayUsingPredicate:predicate];
        
        NSMutableArray *mutableArray = fillteredArray.mutableCopy;
        [mutableArray removeObjectAtIndex:mutableArray.count-1];
        [mutableArray removeObjectAtIndex:0];
        fillteredArray = mutableArray.copy;
        
        photo.srcImageView = fillteredArray[i];
        [photos addObject:photo];
    }
    
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] initWithPhotos:photos currentPhotoIndex:tap.view.tag];
    browser.delegate = self;
    [browser show];
}

#pragma mark - ScrollView Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_pageControlUsed) {
        return;
    }
    
    NSInteger imageCount = _imageNames.count;
    
    CGFloat offsetX = scrollView.contentOffset.x;
    if (offsetX == 0) {
        scrollView.contentOffset = CGPointMake(SCREEN_WIDTH*imageCount, 0);
    }
    if (offsetX == SCREEN_WIDTH*(imageCount+1)) {
        scrollView.contentOffset = CGPointMake(SCREEN_WIDTH, 0);
    }
    
    NSInteger currentPage = scrollView.contentOffset.x/SCREEN_WIDTH - 0.5;
    self.pageControl.currentPage = currentPage;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _pageControlUsed = YES;
    [self removeTimer];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    _pageControlUsed = NO;
    [self addTimer];
}

#pragma mark - Lazy Loading

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [_scrollView setBackgroundColor:[UIColor whiteColor]];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.autoresizesSubviews = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]initWithFrame: CGRectMake(0,
                                                                       self.frame.size.height-kPageControlBottomSpace,
                                                                       self.frame.size.width,
                                                                       kPageControlBottomSpace)];
        _pageControl.numberOfPages = [_imageNames count];
        [_pageControl setBackgroundColor:[UIColor clearColor]];
        [_pageControl setUserInteractionEnabled:NO];
        [_pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
        [_pageControl setCurrentPageIndicatorTintColor:[UIColor whiteColor]];
    }
    return _pageControl;
}

#pragma mark - <MJPhotoBrowserDelegate>
- (void)photoBrowser:(MJPhotoBrowser *)photoBrowser didChangedToPageAtIndex:(NSUInteger)index {
    NSLog(@"index==%lu", (unsigned long)index);
    [_scrollView setContentOffset:CGPointMake(index*_scrollView.frame.size.width+_scrollView.frame.size.width, _scrollView.contentOffset.y) animated:NO];
}

- (void)photoBrowserDidEndShowing:(MJPhotoBrowser *)photoBrowser {
    [self addTimer];
}

@end
