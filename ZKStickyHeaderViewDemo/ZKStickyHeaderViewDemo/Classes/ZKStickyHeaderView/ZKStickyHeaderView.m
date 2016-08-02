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

@interface ZKStickyHeaderView() <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray <NSString *> *imageNames;

@property (nonatomic, assign) BOOL                 pageControlUsed;
@property (nonatomic, strong) NSMutableArray       *viewControllers;
@property (nonatomic, strong) UIScrollView         *scrollView;
@property (nonatomic, strong) UIPageControl        *pageControl;
@property (nonatomic, strong) UIView               *contentView;

@end

static CGFloat const kPageControlBottomSpace = 15.0f;

@implementation ZKStickyHeaderView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _isExpanded = NO;
    }
    return self;
}

+ (instancetype)headerViewWithImageNames:(NSArray<NSString *> *)imageNames initFrame:(CGRect)initFrame
{
    ZKStickyHeaderView *headerView = [[ZKStickyHeaderView alloc] initWithFrame:initFrame];
    headerView.imageNames = imageNames;
    return headerView;
}

#pragma mark - Setter
- (void)setImageNames:(NSArray<NSString *> *)imageNames
{
    _imageNames = imageNames;
    
    
    _contentView = [[UIView alloc] init];
    _contentView.frame = (CGRect){CGPointZero, self.scrollView.contentSize};
    [self.scrollView addSubview:_contentView];
    
    if ([_imageNames count] > 1) {
        [self addSubview:self.pageControl];
    }
    
//    [self loadScrollViewWithPage:0];
//    [self loadScrollViewWithPage:1];
    
    __weak typeof(self) weakSelf = self;
    [_imageNames enumerateObjectsUsingBlock:^(NSString *string, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf loadScrollViewWithPage:idx];
    }];
}

#pragma mark - Private Mehods
- (void)updateFrame:(CGRect)rect
{
    self.frame = rect;
    _scrollView.frame = rect;
    
    float y = self.frame.size.height + _scrollView.frame.origin.y - kPageControlBottomSpace;
    _pageControl.frame = CGRectMake(0.0f, y, self.frame.size.width, kPageControlBottomSpace);
}

- (void)updateFrameWhenTap
{
    [self updateFrame:self.isExpanded ? [UIScreen mainScreen].bounds : HEADER_INIT_FRAME];
}

- (void)updateFrameWhenScroll
{
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

- (UITableView *)superTableView
{
   id view = [self superview];

    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = [view superview];
    }
    
    return (UITableView *)view;
}

#pragma mark - UITapGestureRecognizer
- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if ([_delegate respondsToSelector:@selector(stickyHeaderViewDidTap:)]) {
        [_delegate stickyHeaderViewDidTap:self];
    }
    
    [self showPhotoBrowserWithTap:tap];
    
//    [self expand];
}

- (void)showPhotoBrowserWithTap:(UITapGestureRecognizer *)tap
{
    NSInteger count = _imageNames.count;
    // 1.封装图片数据
    NSMutableArray <MJPhoto *> *photos = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i<count; i++) {
        // 替换为大尺寸图片 中:bmiddle  大:large
        NSString *url = _imageNames[i];
        MJPhoto *photo = [[MJPhoto alloc] init];
        photo.url = [NSURL URLWithString:url]; // 图片路径
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"class == %@", [UIImageView class]];
        NSArray *tempArray = [[NSArray alloc] init];
        tempArray = [_contentView.subviews filteredArrayUsingPredicate:predicate];
        
        photo.srcImageView = tempArray[i]; // 来源于哪个UIImageView
        [photos addObject:photo];
    }
    
    // 2.显示相册
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] initWithPhotos:photos currentPhotoIndex:tap.view.tag];
    [browser show];
}

- (void)expand
{
    [UIView animateWithDuration:0.35
                     animations:^{
                         
                         self.isExpanded = !self.isExpanded;
                         [self updateFrameWhenTap];
                         
                     } completion:^(BOOL finished){
                         
                         [[self superTableView] setScrollEnabled:!self.isExpanded];
                         
                     }];
}

#pragma mark - Load ScrollView Pages
- (void)loadScrollViewWithPage:(NSInteger)page {
    
    if (page < 0 || page >= _imageNames.count) {
        return;
    }
    
    UIImageView *controller = self.viewControllers[page];
    
    if ((NSNull *)controller == [NSNull null]) {
        
        controller = [[UIImageView alloc] init];
        controller.userInteractionEnabled = YES;
        CGRect frame = _scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.frame = frame;
        [controller setContentMode:UIViewContentModeScaleAspectFill];
        controller.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [controller.layer setMasksToBounds:YES];
        [_contentView addSubview:controller];
        
        controller.tag = page;
        [controller addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                            initWithTarget:self action:@selector(handleTap:)]];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner setCenter:CGPointMake(controller.center.x, controller.center.y)];
        [spinner startAnimating];
        [controller addSubview:spinner];
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            for (int i = 0; i < _imageNames.count; i++) {
                
                if (page == i) {
                    
                    [_viewControllers replaceObjectAtIndex:page withObject:controller];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
//                        [controller setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Resources.bundle/%@.png",_imageNames[i]]]];
                        [controller sd_setImageWithURL:[NSURL URLWithString:_imageNames[i]] placeholderImage:nil];
                        
                        [spinner removeFromSuperview];
                        
                        return;
                    });
                }
            }
        });
    }
}

#pragma mark - ScrollView Methods
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (_pageControlUsed) {
        return;
    }
    
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageControl.currentPage = page;
    
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _pageControlUsed = YES;
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    _pageControlUsed = NO;
}

#pragma mark - Lazy Loading
- (NSMutableArray *)viewControllers
{
    if (!_viewControllers) {
        NSMutableArray *controllers = [[NSMutableArray alloc] init];
        for (unsigned i = 0; i < [_imageNames count]; i++) {
            [controllers addObject:[NSNull null]];
        }
        _viewControllers = controllers;
    }
    return _viewControllers;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [self addSubview:_scrollView];
        _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * _imageNames.count, _scrollView.frame.size.height);
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

- (UIPageControl *)pageControl
{
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

@end
