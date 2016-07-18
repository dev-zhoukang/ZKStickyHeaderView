//
//  ZKMainViewController.m
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import "ZKMainViewController.h"
#import "ZKStickyHeaderView.h"

#define HEADER_HEIGHT 200.0f
#define HEADER_INIT_FRAME CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT)

@interface ZKMainViewController () <UITableViewDataSource, UITableViewDelegate, ZKStickyHeaderViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) ZKStickyHeaderView *headerView;

@end

@implementation ZKMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createHeaderView];
}

- (void)createHeaderView
{
    _headerView = [[ZKStickyHeaderView alloc]initWithFrame:HEADER_INIT_FRAME];
    _headerView.delegate = self;
    [_tableView setTableHeaderView:_headerView];
}

#pragma mark *** <<UITableViewDataSource, UITableViewDelegate>> ***
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentify = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd", indexPath.item];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float delta = 0.0f;
    CGRect rect = HEADER_INIT_FRAME;
    
    // Only allow the header to stretch if pulled down
    if (_tableView.contentOffset.y < 0.0f)
    {
        // Scroll down
        delta = fabs(MIN(0.0f, _tableView.contentOffset.y));
    }
    
    rect.origin.y -= delta;
    rect.size.height += delta;
    
    [_headerView updateFrame:rect];
    
}

#pragma mark *** <ZKStickyHeaderViewDelegate> ***
- (void)toggleHeaderViewFrame
{
    [UIView animateWithDuration:0.35
                     animations:^{
                         
                         _headerView.isExpanded = !_headerView.isExpanded;
                         [_headerView updateFrame:_headerView.isExpanded ? [self.view frame] : HEADER_INIT_FRAME];
                         
                     } completion:^(BOOL finished){
                         
                         [_tableView setScrollEnabled:!_headerView.isExpanded];
                         
                     }];
    
}

@end
