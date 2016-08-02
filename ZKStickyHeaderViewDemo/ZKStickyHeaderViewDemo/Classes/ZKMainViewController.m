//
//  ZKMainViewController.m
//  ZKStickyHeaderViewDemo
//
//  Created by ZK on 16/7/18.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import "ZKMainViewController.h"
#import "ZKStickyHeaderView.h"

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
    NSArray *imageNames = @[@"iPhone1",@"iPhone2",@"iPhone3",@"iPhone4",@"iPhone5",@"iPhone6"];
    _headerView = [ZKStickyHeaderView headerViewWithImageNames:imageNames initFrame:HEADER_INIT_FRAME];
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
    [_headerView updateFrameWhenScroll];
}

@end
