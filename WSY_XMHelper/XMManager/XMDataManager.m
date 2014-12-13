//
//  XMDataManager.m
//  WSY_LOLHelper
//
//  Created by 袁仕崇 on 14/12/6.
//  Copyright (c) 2014年 wilson. All rights reserved.
//

#import "XMDataManager.h"
#import "XMHelper.h"
#import "XMVideoDownloader.h"

typedef NS_ENUM(NSInteger, XMDownloadStatus) {
    XMDownloadStateDownloadNow,
    XMDownloadStateDownloadStop,
};

@interface XMDataManager()
@property (nonatomic, strong) NSDictionary *qualityDic;
@property (nonatomic, strong) NSMutableArray *downloadSqueue;
@property (nonatomic, assign) XMDownloadStatus downloadStatus;

@end

@implementation XMDataManager
+ (instancetype)defaultDataManager
{
    GCDSharedInstance(^{
        return [[self alloc] init];
    });
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.downloadList = [NSMutableArray new];
        self.downloadNow = [NSMutableDictionary new];
        self.downloadSqueue = [NSMutableArray new];
        self.qualityDic = @{@"0": @"video_addr", @"1": @"video_addr_high", @"2": @"video_addr_super"};
        
        self.downloadStatus = XMDownloadStateDownloadStop;
    }
    return self;
}


- (void)xm_videoListWithVideoType: (VIDEO_TYPE)type
{
    [[[XMRequest defaultRequest] fetchJSONFromUrlString:[XMAPI api_videoListWithVideoType:type]] subscribeNext:^(NSArray *list) {
        self.videoList = list;
    }];
}
- (void)xm_detailListWithType:(VIDEO_TYPE)type name:(NSString *)name page:(NSInteger)page
{
    [[[XMRequest defaultRequest] fetchJSONFromUrlString:[XMAPI api_seriesWithType:type name:name page:page]] subscribeNext:^(NSArray *list) {
        self.detailList = list;
    }];
}

- (void)xm_addVideoDownloadwithVideoDic:(NSDictionary *)videoDic
{
    [self.downloadList addObject:videoDic];
//    [self downloader_startDownloadWithVideoDic:videoDic];
    [self downloader_addDownloadToSqeue:videoDic];
}
- (void)downloader_addDownloadToSqeue: (NSDictionary *)videoDic
{
    
    [self.downloadSqueue addObject:videoDic];
    [self downloader_startDownload];
    
}


- (void)downloader_startDownload
{
    
    NSDictionary *videoDic = [self.downloadSqueue firstObject];
    NSString *videoName = videoDic[@"name"];
    NSMutableDictionary *videoInfo = [NSMutableDictionary new];
    
    //开始下载
    if (self.downloadStatus == XMDownloadStateDownloadNow) {
        return;
    }
    self.downloadStatus = XMDownloadStateDownloadNow;
    @weakify(self);
    [[XMVideoDownloader defaultDownloader] downloader_StartDownLoadWithName:videoDic[@"youku_id"] urlString:videoDic[@"urlString"]  downloadProgress:^(float progress) {
        @strongify(self);
        NSString *progressString = [NSString stringWithFormat:@"%.2f", progress];
        [videoInfo removeAllObjects];
        [self.downloadNow removeAllObjects];
        [self willChangeValueForKey:@"downloadNow"];
        [videoInfo setValue:progressString forKey:@"progress"];
        [videoInfo setValue:videoName  forKey:@"name"];
        [self.downloadNow setObject:videoInfo forKey:@"download"];
        [self didChangeValueForKey:@"downloadNow"];
    } completionHandler:^{
        @strongify(self);
        [self.downloadSqueue removeObject:videoDic];
        self.downloadStatus = XMDownloadStateDownloadStop;
        if (self.downloadSqueue.count != 0) {
            [self downloader_startDownload];
        }
    } failedHandler:^{
        NSLog(@"DownLoadError");
    }];
    
}


@end