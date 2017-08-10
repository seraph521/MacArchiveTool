//
//  ArchieveTool.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/7/12.
//  Copyright © 2017年 XFX. All rights reserved.
//


#import "ArchieveTool.h"

static ArchieveTool * archieveTool;

@implementation ArchieveTool

+ (instancetype)allocWithZone:(struct _NSZone *)zone{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        archieveTool = [super allocWithZone:zone];
    });
    return archieveTool;
}

+ (instancetype) sharedInstance{
    
    return   [[self alloc] init];
}


-(id) copyWithZone:(struct _NSZone *)zone
{
    return archieveTool ;
}

@end
