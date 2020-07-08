import XCTest
import QCloudCOSXML

class ModifyObjectProperty: XCTestCase,QCloudSignatureProvider,QCloudCredentailFenceQueueDelegate{
    
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
     * 修改对象元数据 调用QCloudPutObjectCopyRequest 接口 文件名 文件路径 保持与源文件一致，
     * 然后自定义元数据，复制成功以后，删除源文件；
     */
    func modifyObjectMetadata() {
        let exception = XCTestExpectation.init(description: "modifyObjectMetadata");
        
        //.cssg-snippet-body-start:[swift-modify-object-metadata]
        let request : QCloudPutObjectCopyRequest = QCloudPutObjectCopyRequest();
        
        //目标存储桶名
        request.bucket = "examplebucket-1250000000";
        
        //目标文件的对象键
        request.object = "exampleobject";
        
        // 是否拷贝元数据，枚举值：Copy，Replaced，默认值 Copy。
        // 假如标记为 Copy，忽略 Header 中的用户元数据信息直接复制
        // 假如标记为 Replaced，按 Header 信息修改元数据。当目标路径和原路径一致，即用户试图修改元数据时，必须为 Replaced
        request.metadataDirective = "Replaced";
        
        //  自定义对象header
        request.customHeaders.setValue("newValue", forKey: "x-cos-meta-*")
        //定义 Object 的 ACL 属性，有效值：private，public-read，default。
        //默认值：default（继承 Bucket 权限）。
        //注意：当前访问策略条目限制为1000条，如果您无需进行 Object ACL 控制，请填 default
        //或者此项不进行设置，默认继承 Bucket 权限。
        request.accessControlList = "default";
        //源对象所在的路径
        request.objectCopySource = "sourcebucket-1250000000.cos.COS_REGION.myqcloud.com/sourceObject";
        
        //指定源文件的 versionID，只有开启或开启后暂停的存储桶，才会响应此参数
        request.versionID = "versionID";
        request.setFinish { (result, error) in
            //result 返回具体信息
            exception.fulfill();
            XCTAssertNil(error);
            XCTAssertNotNil(result);
        }
        
        QCloudCOSXMLService.defaultCOSXML().putObjectCopy(request);
        //.cssg-snippet-body-end
        
        self.wait(for: [exception], timeout: 100);
    }
    
    
    // 修改对象存储类型
    func modifyObjectStorageClass() {
        let exception = XCTestExpectation.init(description: "modifyObjectStorageClass");
        
        //.cssg-snippet-body-start:[swift-modify-object-storage-class]
        let request : QCloudPutObjectCopyRequest = QCloudPutObjectCopyRequest();
        
        //目标存储桶名
        request.bucket = "examplebucket-1250000000";
        
        //目标文件的对象键
        request.object = "exampleobject";
        
        //    对象存储类型，枚举值请参见 存储类型 文档，例如 MAZ_STANDARD，MAZ_STANDARD_IA，
        //    STANDARD_IA，ARCHIVE。仅当对象不是标准存储（STANDARD）时才会返回该头部
        request.customHeaders.setValue("newValue", forKey: "x-cos-storage-class");
        //源对象所在的路径
        request.objectCopySource = "sourcebucket-1250000000.cos.COS_REGION.myqcloud.com/sourceObject";
        
        //指定源文件的 versionID，只有开启或开启后暂停的存储桶，才会响应此参数
        request.versionID = "versionID";
        request.setFinish { (result, error) in
            //result 返回具体信息
            exception.fulfill();
            XCTAssertNil(error);
            XCTAssertNotNil(result);
        }
        
        QCloudCOSXMLService.defaultCOSXML().putObjectCopy(request);
        //.cssg-snippet-body-end
        
        self.wait(for: [exception], timeout: 100);
    }
    
    
    func testModifyObjectProperty() {
        // 修改对象元数据
        self.modifyObjectMetadata();
        // 修改对象存储类型
        self.modifyObjectStorageClass();
    }
}
