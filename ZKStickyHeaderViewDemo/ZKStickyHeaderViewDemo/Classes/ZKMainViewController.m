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
    NSArray *imageUrls = @[
//                           @"http://ww3.sinaimg.cn/large/8e88b0c1gw1e9lpr0nly5j20pf0gygo6.jpg",
//                           @"http://ww4.sinaimg.cn/large/8e88b0c1gw1e9lpr1d0vyj20pf0gytcj.jpg",
//                           @"http://ww3.sinaimg.cn/large/8e88b0c1gw1e9lpr1xydcj20gy0o9q6s.jpg",
                           @"http://ww2.sinaimg.cn/large/8e88b0c1gw1e9lpr2n1jjj20gy0o9tcc.jpg",
                           @"http://ww2.sinaimg.cn/large/8e88b0c1gw1e9lpr39ht9j20gy0o6q74.jpg",
                           @"http://ww3.sinaimg.cn/large/8e88b0c1gw1e9lpr3xvtlj20gy0obadv.jpg",
                           @"http://ww3.sinaimg.cn/large/8e88b0c1gw1e9lpr57tn9j20gy0obn0f.jpg",
                           @"http://images.himoca.com/dynamic/db/77/13da5b006642a5a95c512cb528058dff.jpg",
                           @"http://images.himoca.com/dynamic/db/77/29b553b49130570391d9288ef09dc39b.jpg"
                           ];
    
    _headerView = [ZKStickyHeaderView headerViewWithImageNames:imageUrls initFrame:HEADER_INIT_FRAME];
    _headerView.delegate = self;
    [_tableView setTableHeaderView:_headerView];
}

#pragma mark *** <<UITableViewDataSource, UITableViewDelegate>> ***
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 25;
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
