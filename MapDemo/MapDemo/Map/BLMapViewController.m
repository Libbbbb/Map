//
//  BLMapViewController.m
//  MapDemo
//
//  Created by 边雷 on 16/11/30.
//  Copyright © 2016年 Mac-b. All rights reserved.
//

#import "BLMapViewController.h"
#import "Masonry.h"
#import <MapKit/MapKit.h>
#import "BLAnnotation.h"
//带界面的语音识别控件
#import "iflyMSC/IFlyRecognizerViewDelegate.h"
#import "iflyMSC/IFlyRecognizerView.h"
#import "iflyMSC/IFlyMSC.h"
#import "ISRDataHelper.h"

@interface BLMapViewController ()<MKMapViewDelegate, UITextFieldDelegate, IFlyRecognizerViewDelegate>
@property(nonatomic, weak) MKMapView *map;
@property(nonatomic, strong) CLLocationManager *mgr;
@property (nonatomic, strong) NSString * result;
@end

@implementation BLMapViewController
{
    UITextField *_tF;
    //  定义一个保存路线的可变数组
    NSMutableArray *_polyLineArr;
    //  定义一个添加大头针数组
    NSMutableArray *_annoArr;
    //记录导航按钮
    UIButton *_dhBtn;
    
     IFlyRecognizerView *_iflyRecognizerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  初始化
    _polyLineArr = [[NSMutableArray alloc]init];
    _annoArr = [[NSMutableArray alloc]init];
    self.view.backgroundColor = [UIColor whiteColor];
    //隐藏返回item
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"地图";
    [self setupUI];
    //添加地图类型
    [self addMapType];
    //添加返回按钮    返回定位点
    [self backBtn];
    //航拍
    [self cameraType];
    //放大缩小
    [self mapScale];
    //添加大头针
    [self addTap];
    //导航
    [self addTextFAndBtn];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"5844ecee"];
    [IFlySpeechUtility createUtility:initString];
    
    //初始化语音识别控件
    _iflyRecognizerView = [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
    _iflyRecognizerView.delegate = self;
    [_iflyRecognizerView setParameter: @"iat" forKey: [IFlySpeechConstant IFLY_DOMAIN]];
    //asr_audio_path保存录音文件名，如不再需要，设置value为nil表示取消，默认目录是documents
    [_iflyRecognizerView setParameter:@"asrview.pcm " forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    //添加语音按钮
    [self IFlyBtn];
    
}

#pragma mark - 语音按钮
- (void)IFlyBtn
{
    UIButton *IFLYBtn = [self buttonWithTitle:@"语音导航"];
    [IFLYBtn addTarget:self action:@selector(clickIFLYBtn) forControlEvents:UIControlEventTouchUpInside];
    
    [IFLYBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_dhBtn.mas_right).offset(5);
        make.centerY.equalTo(_dhBtn.mas_centerY);
    }];
    
}

#pragma mark - 语音按钮点击事件
- (void)clickIFLYBtn
{
    if (_tF.text != nil) {
        _tF.text = nil;
        [_map removeOverlays:_polyLineArr];
        [_polyLineArr removeAllObjects];
    }
    
    //当键盘弹出来时
    [_tF resignFirstResponder];
    
    //启动识别服务
    [_iflyRecognizerView start];
}

/*识别结果返回代理
 @param resultArray 识别结果
 @ param isLast 表示是否最后一次结果
 */
- (void)onResult: (NSArray *)resultArray isLast:(BOOL) isLast
{
    //取消识别
    [_iflyRecognizerView  cancel];
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = resultArray[0];
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    _result =[NSString stringWithFormat:@"%@%@", _tF.text,resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _tF.text = [NSString stringWithFormat:@"%@%@", _tF.text,resultFromJson];
    
    // 语音自动导航
    [self clickDirectionBtn];
    // 返回定位点
    [self backUserLocation];
}
/*识别会话错误返回代理
 @ param  error 错误码
 */
- (void)onError: (IFlySpeechError *) error{}

#pragma mark - 添加地图
- (void)setupUI
{
    MKMapView *map = [[MKMapView alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
    [self.view addSubview:map];
    self.map = map;
    
    //授权   设置info.plist
    self.mgr = [CLLocationManager new];
    if ([self.mgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.mgr requestWhenInUseAuthorization];
    }
    self.map.userTrackingMode = MKUserTrackingModeFollowWithHeading;
    self.map.delegate = self;
    //显示标尺
    self.map.showsScale = YES;

    [self hideBottomLabAndView];
}

#pragma mark - 封装隐藏左右下方的"法律信息"和"高德地图"
- (void)hideBottomLabAndView
{
    /** 删除地图左下角 "法律信息"*/
    UILabel *att = [_map valueForKey:@"attributionLabel"];
    
    /** 直接移除不显示文字, 但是有点击事件*/
    //    [att removeFromSuperview];
    
    /** MKAttributionLabel
     _strokeLabel,
     _innerLabel,
     _mapType,
     _useDarkText
     */
    
    /** 单独设置att的text会崩溃; 需要设置att里面的两个属性的text都为nil时, 才会消失并且也不会有点击事件了*/
    /** 设置两个属性的alpha属性为0时, 也可以隐藏字体, 但是点击事件还在*/
    /** 设置下面两个属性的各种颜色时, 个人测试innerLabel属性的优先级可能高一些*/
    /** 当切换 地图类型 时, "法律信息"label就又出来了, 使用removeFromSuperview解决*/
    UILabel *inner = [att valueForKey:@"innerLabel"];
    //    [inner setTextColor:[UIColor redColor]];
    //    inner.backgroundColor = [UIColor greenColor];
    //    inner.alpha = 0;
    //    [inner setText:nil];
    [inner removeFromSuperview];
    
    UILabel *stro = [att valueForKey:@"strokeLabel"];
    //    stro.textColor = [UIColor redColor];
    //    stro.backgroundColor = [UIColor blueColor];
    //    stro.alpha = 0;
    //    [stro setText:nil];
    [stro removeFromSuperview];
    
    /** 删除右下角" 高德地图 "*/
    /** 将视图的透明度改成0 或者 移除视图都可以*/
    UIView *abv = [_map valueForKey:@"_attributionBadgeView"];
    //    abv.alpha = 0;
    [abv removeFromSuperview];
}

#pragma mark - 定位大头针 反地理编码
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLGeocoder *gecoder = [CLGeocoder new];
    
    CLLocation *location = userLocation.location;
    [gecoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        //判断地标对象
        if (placemarks.count == 0 || error) {
            return ;
        }
        
        //设置数据
        self.map.userLocation.title = placemarks.lastObject.locality;
        self.map.userLocation.subtitle = placemarks.lastObject.name;
    }];
}

#pragma mark - 地图类型
- (void)addMapType
{
    NSArray *arr = @[@"标准",@"卫星",@"混合"];
    UISegmentedControl *seg = [[UISegmentedControl alloc]initWithItems:arr];
    seg.frame = CGRectMake(18, 95, 180, 20);
    seg.selectedSegmentIndex = 0;
    [seg addTarget:self action:@selector(clickSeg:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview: seg];
}

#pragma mark - 地图类型点击事件
- (void)clickSeg:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.map.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.map.mapType = MKMapTypeSatellite;
            break;
        case 2:
            self.map.mapType = MKMapTypeHybrid;
            break;
            
        default:
            break;
    }
}

#pragma mark - 返回定位点
- (void)backBtn
{
    UIButton *btn = [self buttonWithTitle:@" 返回 "];
    
    [btn addTarget:self action:@selector(backUserLocation) forControlEvents:UIControlEventTouchUpInside];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
        make.left.equalTo(self.view.mas_left).offset(10);
    }];
}
/** 返回按钮点击事件*/
- (void)backUserLocation
{
    //  方式一:  修改用户定位跟踪模式 并实现动画
//    [self.map setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    
    //  方式二:修改地图显示的范围 -> 定位的范围
    //  中心点 = 定位点
    CLLocationCoordinate2D center = self.map.userLocation.location.coordinate;
    //  跨度 = 当前地图的跨度
    MKCoordinateSpan span = self.map.region.span;
    [self.map setRegion:MKCoordinateRegionMake(center, span) animated:YES];
}

#pragma mark - 航拍
- (void)cameraType
{
    UIButton *btn = [self buttonWithTitle:@" 航拍 "];
    
    [btn addTarget:self action:@selector(clickCameraBtn) forControlEvents:UIControlEventTouchUpInside];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
        make.left.equalTo(self.view.mas_left).offset(10);
    }];
}
/** 航怕点击事件*/
- (void)clickCameraBtn
{
    self.map.camera = [MKMapCamera cameraLookingAtCenterCoordinate:CLLocationCoordinate2DMake(self.map.userLocation.location.coordinate.latitude, self.map.userLocation.location.coordinate.longitude) fromDistance:30 pitch:75 heading:0];
}

#pragma mark - 封装btn方法
- (UIButton *)buttonWithTitle: (NSString *)title
{
    UIButton *btn = [[UIButton alloc]init];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    btn.backgroundColor = [UIColor colorWithRed:21/255.0 green:126/255.0 blue:251/255.0 alpha:1];
    btn.layer.cornerRadius = 10;
    btn.layer.borderWidth = 1;
    [btn sizeToFit];
    [self.view addSubview:btn];
    return btn;
}

#pragma mark - 地图放大和缩小
- (void)mapScale
{
    UIButton *btnBig = [self buttonWithTitle:@"➕"];
    
    [btnBig addTarget:self action:@selector(clickMapScaleBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [btnBig mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
        make.right.equalTo(self.view.mas_right).offset(-10);
    }];
    
    UIButton *btnSmall = [self buttonWithTitle:@"➖"];
    
    [btnSmall addTarget:self action:@selector(clickMapScaleBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [btnSmall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).offset(-20);
        make.right.equalTo(self.view.mas_right).offset(-10);
    }];
}
/** ➕,➖点击事件*/
- (void)clickMapScaleBtn: (UIButton *)btn
{
    //  中心点
    CLLocationCoordinate2D center = self.map.region.center;
    //  跨度
    MKCoordinateSpan span;

    if ([btn.titleLabel.text isEqualToString:@"➕"]) {
        span = MKCoordinateSpanMake(self.map.region.span.latitudeDelta / 2, self.map.region.span.longitudeDelta / 2);
    } else {
        span = MKCoordinateSpanMake(self.map.region.span.latitudeDelta * 2, self.map.region.span.longitudeDelta * 2);
    }
    //当跨度到最大时 会崩溃
    if (span.latitudeDelta > 100) {
        return;
    }
    
    [self.map setRegion:MKCoordinateRegionMake(center, span) animated:YES];
//    NSLog(@"%f, %f", self.map.region.span.latitudeDelta,self.map.region.span.longitudeDelta);
}

#pragma mark - 大头针
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_tF resignFirstResponder];
}

#pragma mark - 添加点按手势添加大头针
- (void)addTap
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    [self.map addGestureRecognizer:tap];
}

/** 手势事件*/
- (void)tapAction: (UITapGestureRecognizer *)recognizer
{
    //  当地图导航时不添加大头针
    if (_polyLineArr.count != 0) {
        return;
    }
    if (_annoArr != nil) {
        [self.map removeAnnotations:_annoArr];
        [_annoArr removeAllObjects];
    }
    CGPoint point = [recognizer locationInView:self.map];
    [self anno:point];
    
}
/** 封装大头针*/
- (void)anno: (CGPoint)point
{
    //  创建大头针
    BLAnnotation *anno = [BLAnnotation new];
    //  获取点击点的坐标
    //  坐标转换    坐标 -> 经纬度
    CLLocationCoordinate2D coor = [self.map convertPoint:point toCoordinateFromView:self.map];
    //  设置属性
    anno.coordinate = coor;
    
    CLGeocoder *gecoder = [CLGeocoder new];
    
    CLLocation *location = [[CLLocation alloc]initWithLatitude:coor.latitude longitude:coor.longitude];
    [gecoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        //判断地标对象
        if (placemarks.count == 0 || error) {
            return ;
        }
        
        anno.title = placemarks.lastObject.locality;
        anno.subtitle = placemarks.lastObject.name;
    }];
    [self.map addAnnotation:anno];
    [_annoArr addObject:anno];
    
    /** 添加大头针视图时也存在内存优化问题, iOS已经针对大头针视图进行了重用优化!!!*/
}


#pragma Mark - 当设置地图的大头针视图时调用   -> 解决大头针视图的重用
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //过滤定位大头针
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        //定位大头针显示默认样式
        return nil;
    }
    
    static NSString *identifier = @"anno";
    MKAnnotationView *annoV = [self.map dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (annoV == nil) {
        annoV = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
        //设置数据
        annoV.image = [UIImage imageNamed:@"大头针"];
        //设置标注
        annoV.canShowCallout = YES;
        //设置yes大头针可以拖动
//        annoV.draggable = YES;
        //大头针显示信息的自定义控件
        annoV.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoLight];
//        annoV.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoDark];
//        annoV.detailCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeContactAdd];
    }

    return annoV;
}

#pragma mark - 大头针动画 -> 从上掉下来
/** 已经添加大头针视图后调用(还未显示) , 该方法专门用于设置大头针自定义动画的*/
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views
{
    for (MKAnnotationView *annoV in views) {
        if ([annoV.annotation isKindOfClass:[MKUserLocation class]]) {
            return;
        }
        
        //记录大头针frame
        CGRect rect = annoV.frame;
        //改变大头针frame
        annoV.frame = CGRectMake(rect.origin.x, 0, rect.size.width, rect.size.height);
        
        [UIView animateWithDuration:0.3 animations:^{
            annoV.frame = rect;
        }];
    }
}

#pragma mark - 自定义导航    -> 将起点$终点直接传递给服务器, 服务器返回数据
/** 设置地址栏 和导航按钮*/
- (void)addTextFAndBtn
{
    UITextField *tF = [[UITextField alloc]initWithFrame:CGRectMake(18, 120, 180, 20)];
    //  设置边框
    tF.borderStyle = UITextBorderStyleRoundedRect;
    tF.backgroundColor = [UIColor whiteColor];
    tF.placeholder = @"请输入目标地址:";
    tF.font = [UIFont systemFontOfSize:12];
    //  一次性删除文字
    tF.clearButtonMode = UITextFieldViewModeAlways;
    //  内容对齐方式
    tF.textAlignment = NSTextAlignmentLeft;
    //  return键变成什么键
    tF.returnKeyType = UIReturnKeyDone;
    tF.delegate = self;
    [self.view addSubview:tF];
    _tF = tF;
    
    UIButton *btn = [self buttonWithTitle:@"导航"];
    [btn addTarget:self action:@selector(clickDirectionBtn) forControlEvents:UIControlEventTouchUpInside];
    
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_tF.mas_right).offset(10);
        make.centerY.equalTo(_tF.mas_centerY);
    }];
    _dhBtn = btn;
}

/** 导航点击事件*/
- (void)clickDirectionBtn
{
    //  判断数组里是否有线
    if (_polyLineArr != nil) {
        [self.map removeOverlays:_polyLineArr];
        [_polyLineArr removeAllObjects];
    }
    //点击导航时收起键盘
    [_tF resignFirstResponder];
    //  1.创建导航请求对象
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    //  设置起点    ->把定位点转移成地图项目
    request.source = [MKMapItem mapItemForCurrentLocation];
    //  设置终点    地理编码
    CLGeocoder *gecoder = [[CLGeocoder alloc]init];
    [gecoder geocodeAddressString:_tF.text completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        //  添加判断    当_tF.text为空时崩溃
        if (placemarks.count == 0 || error) {
            return ;
        }
        MKPlacemark *pm = [[MKPlacemark alloc]initWithPlacemark:placemarks.lastObject];
        //  给终点添加大头针
        CGPoint point = [self.map convertCoordinate:pm.coordinate toPointToView:self.map];
        if (_annoArr != nil) {
            [self.map removeAnnotations:_annoArr];
            [_annoArr removeAllObjects];
        }
        [self anno:point];
        request.destination = [[MKMapItem alloc]initWithPlacemark:pm];        
        
        //  2.创建导航对象
        MKDirections *directions = [[MKDirections alloc]initWithRequest:request];
        //  计算路线
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
            //  获取路线对象  记录路线信息
            MKRoute *route = response.routes.lastObject;
            for (MKRouteStep *step in route.steps) {
                
                //  需要项目中获取的系统数据显示中文,则可以设置项目开发区域为China(info.plist)
                //  遍历step可以得到路线的详细信息   -   供后续开发使用
//                NSLog(@"%@", step.instructions);
            }
            //  地图画线
            [self.map addOverlay:route.polyline];
            [_polyLineArr addObject:route.polyline];
        }];
        
    }];
}

#pragma mark - 设置覆盖物样式时调用   画线
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    //  设置折线的样式 设置MKOverlayRenderer的折线子类
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    //  设置属性
    renderer.strokeColor = [UIColor greenColor];
    renderer.lineWidth = 3;
    
    return renderer;
}

/** 结束编辑*/
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
