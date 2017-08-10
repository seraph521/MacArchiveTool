//
//  ArchieveTool.h
//  自动打包器
//
//  Created by LT-MacbookPro on 17/7/12.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArchieveTool : NSObject

+ (instancetype) sharedInstance;

@property(nonatomic,copy) NSString * pathString;

@end
