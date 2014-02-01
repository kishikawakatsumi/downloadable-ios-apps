//
//  AppDelegate.m
//  JSBTwitter
//
//  Created by kishikawa katsumi on 2014/02/01.
//  Copyright (c) 2014年 kishikawa katsumi. All rights reserved.
//

#import "AppDelegate.h"
#import <zipzap/zipzap.h>
#import <JavaScriptBridge/JavaScriptBridge.h>

static BOOL flag = YES;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *version = [userDefaults stringForKey:@"version"];
    NSString *nextVersion = nil;
    
    NSURL *applicationURL = nil;
    if (!version || [version isEqualToString:@"1.0"]) {
        applicationURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/hlclxi4nofi7tta/1.0.zip"];
        nextVersion = @"1.1";
    } else {
        applicationURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/bcou7nhztewexp9/1.1.zip"];
        nextVersion = @"1.0";
    }
    [self loadApplicationWithURL:applicationURL];
    
    [userDefaults setObject:nextVersion forKey:@"version"];
    [userDefaults synchronize];
    
    return YES;
}

- (void)loadApplicationWithURL:(NSURL *)applicationURL
{
    self.window.rootViewController = nil;
    self.window = nil;
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:applicationURL] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths.firstObject;
        documentDirectory = [documentDirectory stringByAppendingPathComponent:[applicationURL lastPathComponent]];
        
        NSString *mainScriptPath = nil;
        NSString *scriptRoot = nil;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        ZZArchive *archive = [ZZArchive archiveWithData:data];
        for (ZZArchiveEntry *entry in archive.entries) {
            NSString *targetPath = [documentDirectory stringByAppendingPathComponent:entry.fileName];
            
            if (entry.fileMode & S_IFDIR) {
                [fileManager createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
            } else {
                [fileManager createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                [entry.newData writeToFile:targetPath atomically:NO];
                
                if ([targetPath hasSuffix:@"main.js"]) {
                    mainScriptPath = targetPath;
                    scriptRoot = [targetPath stringByDeletingLastPathComponent];
                }
            }
        }
        
        NSString *script = [NSString stringWithContentsOfFile:mainScriptPath encoding:NSUTF8StringEncoding error:nil];
        
        JSContext *context = [JSBScriptingSupport globalContext];
        [context addScriptingSupport:@"Accounts"];
        [context addScriptingSupport:@"Social"];
        
        context[@"SCRIPT_ROOT"] = scriptRoot;
        
        [context evaluateScript:script];
        
        flag = !flag;
    }];
}

@end
