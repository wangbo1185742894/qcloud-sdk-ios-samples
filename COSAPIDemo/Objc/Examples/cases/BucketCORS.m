#import <XCTest/XCTest.h>
#import <QCloudCOSXML/QCloudCOSXML.h>
#import <QCloudCOSXML/QCloudUploadPartRequest.h>
#import <QCloudCOSXML/QCloudCompleteMultipartUploadRequest.h>
#import <QCloudCOSXML/QCloudAbortMultipfartUploadRequest.h>
#import <QCloudCOSXML/QCloudMultipartInfo.h>
#import <QCloudCOSXML/QCloudCompleteMultipartUploadInfo.h>


@interface BucketCORS : XCTestCase <QCloudSignatureProvider, QCloudCredentailFenceQueueDelegate>

@property (nonatomic) QCloudCredentailFenceQueue* credentialFenceQueue;

@end

@implementation BucketCORS

- (void)setUp {
    // 注册默认的 COS 服务
    QCloudServiceConfiguration* configuration = [QCloudServiceConfiguration new];
    configuration.appID = @"1250000000";
    configuration.signatureProvider = self;
    QCloudCOSXMLEndPoint* endpoint = [[QCloudCOSXMLEndPoint alloc] init];
    endpoint.regionName = @"ap-guangzhou";//服务地域名称，可用的地域请参考注释
    configuration.endpoint = endpoint;
    [QCloudCOSXMLService registerDefaultCOSXMLWithConfiguration:configuration];
    [QCloudCOSTransferMangerService registerDefaultCOSTransferMangerWithConfiguration:configuration];

    // 脚手架用于获取临时密钥
    self.credentialFenceQueue = [QCloudCredentailFenceQueue new];
    self.credentialFenceQueue.delegate = self;
}

- (void) fenceQueue:(QCloudCredentailFenceQueue * )queue
    requestCreatorWithContinue:(QCloudCredentailFenceQueueContinue)continueBlock
{
    QCloudCredential* credential = [QCloudCredential new];
    //在这里可以同步过程从服务器获取临时签名需要的 secretID，secretKey，expiretionDate 和 token 参数
    credential.secretID = @"COS_SECRETID";
    credential.secretKey = @"COS_SECRETKEY";
    credential.token = @"COS_TOKEN";
    /*强烈建议返回服务器时间作为签名的开始时间，用来避免由于用户手机本地时间偏差过大导致的签名不正确 */
    credential.startDate = [[[NSDateFormatter alloc] init] dateFromString:@"startTime"]; // 单位是秒
    credential.experationDate = [[[NSDateFormatter alloc] init] dateFromString:@"expiredTime"];
    QCloudAuthentationV5Creator* creator = [[QCloudAuthentationV5Creator alloc]
        initWithCredential:credential];
    continueBlock(creator, nil);
}

- (void) signatureWithFields:(QCloudSignatureFields*)fileds
                     request:(QCloudBizHTTPRequest*)request
                  urlRequest:(NSMutableURLRequest*)urlRequst
                   compelete:(QCloudHTTPAuthentationContinueBlock)continueBlock
{
    [self.credentialFenceQueue performAction:^(QCloudAuthentationCreator *creator,
                                               NSError *error) {
        if (error) {
            continueBlock(nil, error);
        } else {
            QCloudSignature* signature =  [creator signatureForData:urlRequst];
            continueBlock(signature, nil);
        }
    }];
}

/**
 * 设置存储桶跨域规则
 */
- (void)putBucketCors {

    //.cssg-snippet-body-start:[objc-put-bucket-cors]
    QCloudPutBucketCORSRequest* putCORS = [QCloudPutBucketCORSRequest new];
    QCloudCORSConfiguration* cors = [QCloudCORSConfiguration new];
    
    QCloudCORSRule* rule = [QCloudCORSRule new];
    
    // 配置规则的 ID
    rule.identifier = @"sdk";
    
    // 在发送 OPTIONS 请求时告知服务端，接下来的请求可以使用哪些自定义的 HTTP 请求头部，支持通配符 *
    rule.allowedHeader = @[@"origin",@"host",@"accept",@"content-type",@"authorization"];
    rule.exposeHeader = @"ETag";
    
    // 允许的 HTTP 操作，例如：GET，PUT，HEAD，POST，DELETE
    rule.allowedMethod = @[@"GET",@"PUT",@"POST", @"DELETE", @"HEAD"];
    
    // 设置 OPTIONS 请求得到结果的有效期
    rule.maxAgeSeconds = 3600;
    
    // 允许的访问来源，支持通配符 *，格式为：协议://域名[:端口]
    rule.allowedOrigin = @"http://cloud.tencent.com";
    cors.rules = @[rule];
    putCORS.corsConfiguration = cors;
    
    //格式：BucketName-APPID
    putCORS.bucket = @"examplebucket-1250000000";
    [putCORS setFinishBlock:^(id outputObject, NSError *error) {
        //可以从 outputObject 中获取服务器返回的 header 信息
        NSDictionary * result = (NSDictionary *)outputObject;
    }];
    
    [[QCloudCOSXMLService defaultCOSXML] PutBucketCORS:putCORS];
    
    //.cssg-snippet-body-end

}

/**
 * 获取存储桶跨域规则
 */
- (void)getBucketCors {

    //.cssg-snippet-body-start:[objc-get-bucket-cors]
    QCloudGetBucketCORSRequest* corsReqeust = [QCloudGetBucketCORSRequest new];
    
    //格式：BucketName-APPID
    corsReqeust.bucket = @"examplebucket-1250000000";
    
    [corsReqeust setFinishBlock:^(QCloudCORSConfiguration * _Nonnull result,
                                  NSError * _Nonnull error) {
        //CORS 设置封装在 result 中
        
    }];
    
    [[QCloudCOSXMLService defaultCOSXML] GetBucketCORS:corsReqeust];
    
    //.cssg-snippet-body-end

}

/**
 * 实现 Object 跨域访问配置的预请求
 */
- (void)optionObject {

    //.cssg-snippet-body-start:[objc-option-object]
    QCloudOptionsObjectRequest* request = [[QCloudOptionsObjectRequest alloc] init];
    
    //存储桶名称，格式：BucketName-APPID
    request.bucket =@"examplebucket-1250000000";
    
    //模拟跨域访问的请求来源域名
    request.origin = @"http://cloud.tencent.com";
    request.accessControlRequestMethod = @"GET";
    request.accessControlRequestHeaders = @"host";
    
    //对象位于存储桶中的位置标识符，即对象键
    request.object = @"exampleobject";
    
    [request setFinishBlock:^(id outputObject, NSError* error) {
        //可以从 outputObject 中获取 response 中 etag 或者自定义头部等信息
        NSDictionary* info = (NSDictionary *) outputObject;
        
    }];
    
    [[QCloudCOSXMLService defaultCOSXML] OptionsObject:request];
    
    //.cssg-snippet-body-end

}

/**
 * 删除存储桶跨域规则
 */
- (void)deleteBucketCors {

    //.cssg-snippet-body-start:[objc-delete-bucket-cors]
    QCloudDeleteBucketCORSRequest* deleteCORS = [QCloudDeleteBucketCORSRequest new];
    deleteCORS.bucket = @"examplebucket-1250000000";
    [deleteCORS setFinishBlock:^(id outputObject, NSError *error) {
        //可以从 outputObject 中获取服务器返回的 header 信息
       NSDictionary* info = (NSDictionary *) outputObject;
    }];
    [[QCloudCOSXMLService defaultCOSXML] DeleteBucketCORS:deleteCORS];
    
    //.cssg-snippet-body-end

}


- (void)testBucketCORS {
    // 设置存储桶跨域规则
    [self putBucketCors];
        
    // 获取存储桶跨域规则
    [self getBucketCors];
        
    // 实现 Object 跨域访问配置的预请求
    [self optionObject];
        
    // 删除存储桶跨域规则
    [self deleteBucketCors];
        
}

@end