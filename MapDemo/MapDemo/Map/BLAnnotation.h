//
//  BLAnnotation.h
//  MapDemo
//
//  Created by 边雷 on 16/12/1.
//  Copyright © 2016年 Mac-b. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//  遵守MKAnnotation协议
@interface BLAnnotation : NSObject<MKAnnotation>

//经纬度
@property (nonatomic) CLLocationCoordinate2D coordinate;
//标题
@property (nonatomic, copy, nullable) NSString *title;
//子标题
@property (nonatomic, copy, nullable) NSString *subtitle;

@end
