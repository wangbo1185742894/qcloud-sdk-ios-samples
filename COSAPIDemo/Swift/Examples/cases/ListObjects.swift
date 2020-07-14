import XCTest
import QCloudCOSXML

class ListObjects: XCTestCase,QCloudSignatureProvider,QCloudCredentailFenceQueueDelegate{
    
    var credentialFenceQueue:QCloudCredentailFenceQueue?;
    
    override func setUp() {
        let config = QCloudServiceConfiguration.init();
        config.signatureProvider = self;
        config.appID = "1253653367";
        let endpoint = QCloudCOSXMLEndPoint.init();
        endpoint.regionName = "ap-guangzhou";//服务地域名称，可用的地域请参考注释
        endpoint.useHTTPS = true;
        config.endpoint = endpoint;
        QCloudCOSXMLService.registerDefaultCOSXML(with: config);
        QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(with: config);
        
        // 脚手架用于获取临时密钥
        self.credentialFenceQueue = QCloudCredentailFenceQueue();
        self.credentialFenceQueue?.delegate = self;
    }
    
    func fenceQueue(_ queue: QCloudCredentailFenceQueue!,
                    requestCreatorWithContinue continueBlock: QCloudCredentailFenceQueueContinue!) {
        let cre = QCloudCredential.init();
        //在这里可以同步过程从服务器获取临时签名需要的 secretID，secretKey，expiretionDate 和 token 参数
        cre.secretID = "COS_SECRETID";
        cre.secretKey = "COS_SECRETKEY";
        cre.token = "COS_TOKEN";
        /*强烈建议返回服务器时间作为签名的开始时间，用来避免由于用户手机本地时间偏差过大导致的签名不正确 */
        cre.startDate = DateFormatter().date(from: "startTime"); // 单位是秒
        cre.experationDate = DateFormatter().date(from: "expiredTime");
        let auth = QCloudAuthentationV5Creator.init(credential: cre);
        continueBlock(auth,nil);
    }
    
    func signature(with fileds: QCloudSignatureFields!,
                   request: QCloudBizHTTPRequest!,
                   urlRequest urlRequst: NSMutableURLRequest!,
                   compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        self.credentialFenceQueue?.performAction({ (creator, error) in
            if error != nil {
                continueBlock(nil,error!);
            }else{
                let signature = creator?.signature(forData: urlRequst);
                continueBlock(signature,nil);
            }
        })
    }
    
    
    /**
     * 查询存储桶（Bucket) 下的部分或者全部对象的方法.
     */
    func getBucket() {
        
        //.cssg-snippet-body-start:[swift-get-bucket]
        let getBucketReq = QCloudGetBucketRequest.init();
        getBucketReq.bucket = "examplebucket-1250000000";
        
        //    单次返回的最大条目数量，默认1000
        getBucketReq.maxKeys = 1000;
        getBucketReq.setFinish { (result, error) in
            
            // result 返回具体信息
            //QCloudListBucketResult.contents 桶内文件数组
            //QCloudListBucketResult.commonPrefixes 桶内文件夹数组
            
            if error != nil{
                print(error!);
            }else{
                print( result!.commonPrefixes);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().getBucket(getBucketReq);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    // 获取第二页对象列表
    func getBucketNextPage() {
        
        //.cssg-snippet-body-start:[swift-get-bucket-next-page]
        let getBucketReq = QCloudGetBucketRequest.init();
        getBucketReq.bucket = "examplebucket-1250000000";
        
        //分页参数 默认以UTF-8二进制顺序列出条目，所有列出条目从marker开始
        getBucketReq.marker = "上一页标识";
        //pagesize
        getBucketReq.maxKeys = 10;
        
        getBucketReq.setFinish { (result, error) in
            
            // result 返回具体信息
            //QCloudListBucketResult.contents 桶内文件数组
            //QCloudListBucketResult.commonPrefixes 桶内文件夹数组
            
            if error != nil{
                print(error!);
            }else{
                print( result!.commonPrefixes);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().getBucket(getBucketReq);
        //.cssg-snippet-body-end
        
          
    }
    
    
    // 获取对象列表与子目录
    func getBucketWithDelimiter() {
        
        //.cssg-snippet-body-start:[swift-get-bucket-with-delimiter]
        let getBucketReq = QCloudGetBucketRequest.init();
        getBucketReq.bucket = "examplebucket-1250000000";
        
        //    单次返回的最大条目数量，默认1000
        getBucketReq.maxKeys = 1000;
        
        //    前缀匹配，用来规定返回的文件前缀地址
        getBucketReq.prefix = "self.prefix";
        
        //    定界符为一个符号，如果有 Prefix，则将 Prefix 到 delimiter 之间的相同路径归为一类，
        //    定义为 Common Prefix，然后列出所有 Common Prefix。如果没有 Prefix，则从路径起点开始
        //    delimiter:路径分隔符 固定为 /
        getBucketReq.delimiter = "/";
        
        //分页参数
        getBucketReq.marker = "上一页标识";
        
        getBucketReq.setFinish { (result, error) in
            
            // result 返回具体信息
            //QCloudListBucketResult.contents 桶内文件数组
            //QCloudListBucketResult.commonPrefixes 桶内文件夹数组
            
            if error != nil{
                print(error!);
            }else{
                print( result!.commonPrefixes);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().getBucket(getBucketReq);
        //.cssg-snippet-body-end
        
          
    }
    
    
    func testListObjects() {
        // 获取对象列表
        self.getBucket();
        // 获取第二页对象列表
        self.getBucketNextPage();
        // 获取对象列表与子目录
        self.getBucketWithDelimiter();
    }
}