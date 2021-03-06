//
//  DragView.h
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/26.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DragViewDelegate <NSObject>

- (void)handleDragViewWithPath:(NSString *)path;

@end

@interface DragView : NSView

@property(nonatomic,assign) id <DragViewDelegate> delegate;

@end
