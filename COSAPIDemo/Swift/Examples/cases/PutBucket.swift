import XCTest
import QCloudCOSXML

class PutBucket: XCTestCase,QCloudSignatureProvider,QCloudCredentailFenceQueueDelegate{
    
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
    
    func fenceQueue(_ queue: QCloudCredentailFenceQueue!, requestCreatorWithContinue continueBlock: QCloudCredentailFenceQueueContinue!) {
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
    
    func signature(with fileds: QCloudSignatureFields!, request: QCloudBizHTTPRequest!, urlRequest urlRequst: NSMutableURLRequest!, compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        self.credentialFenceQueue?.performAction({ (creator, error) in
            if error != nil {
                continueBlock(nil,error!);
            }else{
                let signature = creator?.signature(forData: urlRequst);
                continueBlock(signature,nil);
            }
        })
    }
    
    
    // 创建存储桶
    func putBucket() {
        let exception = XCTestExpectation.init(description: "putBucket");
        
        //.cssg-snippet-body-start:[swift-put-bucket]
        let putBucketReq = QCloudPutBucketRequest.init();
        putBucketReq.bucket = "examplebucket-1250000000";
        putBucketReq.finishBlock = {(result,error) in
            //可以从 outputObject 中获取服务器返回的 header 信息
            if error != nil {
                print(error!);
            } else {
                print(result!);
            }
            exception.fulfill();
            XCTAssertNil(error);
            XCTAssertNotNil(result);
        }
        QCloudCOSXMLService.defaultCOSXML().putBucket(putBucketReq);
        
        //.cssg-snippet-body-end
        
        self.wait(for: [exception], timeout: 100);
    }
    
    
    // 创建存储桶并且授予存储桶权限
    func putBucketAndGrantAcl() {
        let exception = XCTestExpectation.init(description: "putBucketAndGrantAcl");
        
        //.cssg-snippet-body-start:[swift-put-bucket-and-grant-acl]
        
        let putBucketReq = QCloudPutBucketRequest.init();
        putBucketReq.bucket = "examplebucket-1250000000";
        //additional actions after finishing
        putBucketReq.bucket = "examplebucket-1250000000";
        
        let appID = "1131975903";//授予全新的账号 ID
        let ownerIdentifier = String.init(format: "qcs::cam::uin/%@:uin/%@",appID,appID);
        let grantString = String.init(format: "id=\"%@\"", ownerIdentifier);
        
        //赋予被授权者读写权限
        putBucketReq.grantFullControl = grantString;
        
        //赋予被授权者读权限
        putBucketReq.grantRead = grantString;
        
        //赋予被授权者写权限
        putBucketReq.grantWrite = grantString;
        putBucketReq.finishBlock = {(result,error) in
            //可以从 outputObject 中获取服务器返回的 header 信息
            if error != nil {
                print(error!);
            } else {
                print(result!);
            }
            exception.fulfill();
            XCTAssertNil(error);
            XCTAssertNotNil(result);
        }
        QCloudCOSXMLService.defaultCOSXML().putBucket(putBucketReq);
        //.cssg-snippet-body-end
        
        self.wait(for: [exception], timeout: 100);
    }
    
    
    func testPutBucket() {
        // 创建存储桶
        self.putBucket();
        // 创建存储桶并且授予存储桶权限
        self.putBucketAndGrantAcl();
    }
}
