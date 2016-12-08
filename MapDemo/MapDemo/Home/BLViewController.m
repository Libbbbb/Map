//
//  BLViewController.m
//  MapDemo
//
//  Created by 边雷 on 16/11/30.
//  Copyright © 2016年 Mac-b. All rights reserved.
//

#import "BLViewController.h"
#import "Masonry.h"
#import "BLMapViewController.h"

@interface BLViewController ()

@end

@implementation BLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor magentaColor];
    
    [self setupUI];
}

//首页
- (void)setupUI
{
    UIButton *btn = [[UIButton alloc]init];
    [btn setTitle:@"显示地图" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn sizeToFit];
    [self.view addSubview:btn];
    
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
}

//点击事件
- (void)clickBtn
{
    BLMapViewController *mvc = [BLMapViewController new];
    
    [self.navigationController pushViewController:mvc animated:YES];
}

@end
