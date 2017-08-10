//
//  main.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/20.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArchieveTool.h"
int main(int argc, const char * argv[]) {

    for (int i=0; i<argc; i++) {
        
        char * str = argv[i];
        NSString * string = [NSString stringWithFormat:@"%s", str];
        if(i == 1){
            ArchieveTool * tool = [ArchieveTool sharedInstance];
            tool.pathString = string;
           // [tool.pathString writeToFile:[NSString stringWithFormat:@"/Users/lt-macbookpro/Desktop/video/demo%d.txt",i] atomically:YES encoding:NSUTF8StringEncoding error:nil];

        }
       
    }
    return NSApplicationMain(argc, argv);
}
