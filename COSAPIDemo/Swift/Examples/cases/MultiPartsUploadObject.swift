import XCTest
import QCloudCOSXML

class MultiPartsUploadObject: XCTestCase,QCloudSignatureProvider,QCloudCredentailFenceQueueDelegate{
    
    var credentialFenceQueue:QCloudCredentailFenceQueue?;
    
    var uploadId : String?;
    
    var parts : Array<QCloudMultipartInfo>?;
    
    
    
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
    
    
    // 初始化分片上传
    func initMultiUpload() {
        
        //.cssg-snippet-body-start:[swift-init-multi-upload]
        let initRequest = QCloudInitiateMultipartUploadRequest.init();
        initRequest.bucket = "examplebucket-1250000000";
        initRequest.object = "exampleobject";
        
        //将作为对象的元数据返回
        initRequest.cacheControl = "cacheControl";
        
        initRequest.contentDisposition = "contentDisposition";
        
        
        //定义 Object 的 ACL 属性。有效值：private，public-read-write，public-read；默认值：private
        initRequest.accessControlList = "public";
        
        //赋予被授权者读的权限。
        initRequest.grantRead = "grantRead";
        
        //赋予被授权者写的权限
        initRequest.grantWrite = "grantWrite";
        
        //赋予被授权者读写权限。 grantFullControl == grantWrite + grantRead
        initRequest.grantFullControl = "grantFullControl";
        
        initRequest.setFinish { (result, error) in
            if error != nil{
                print(error!);
            }else{
                //获取分块上传的 uploadId，后续的上传都需要这个 ID，请保存以备后续使用
                self.uploadId = result!.uploadId;
                print(result!.uploadId);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().initiateMultipartUpload(initRequest);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    // 列出所有未完成的分片上传任务
    func listMultiUpload() {
        
        //.cssg-snippet-body-start:[swift-list-multi-upload]
        let listParts = QCloudListBucketMultipartUploadsRequest.init();
        listParts.bucket = "examplebucket-1250000000";
        listParts.maxUploads = 100;
        listParts.setFinish { (result, error) in
            if error != nil{
                print(error!);
            }else{
                print(result!);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().listBucketMultipartUploads(listParts);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    // 上传一个分片
    func uploadPart() {
        
        //.cssg-snippet-body-start:[swift-upload-part]
        
        let uploadPart = QCloudUploadPartRequest<AnyObject>.init();
        uploadPart.bucket = "examplebucket-1250000000";
        uploadPart.object = "exampleobject";
        uploadPart.partNumber = 1;
        //标识本次分块上传的 ID；使用 Initiate Multipart Upload 接口初始化分块上传时会得到一个 uploadId
        //该 ID 不但唯一标识这一分块数据，也标识了这分块数据在整个文件内的相对位置
        uploadPart.uploadId = "exampleUploadId";
        uploadPart.uploadId = self.uploadId!;
        
        let dataBody:NSData? = "wrwrwrwrwrwwrwrwrwrwrwwwrwrw"
            .data(using: .utf8) as NSData?;
        uploadPart.body = dataBody!;
        uploadPart.setFinish { (result, error) in
            if error != nil{
                print(error!);
            }else{
                let mutipartInfo = QCloudMultipartInfo.init();
                //获取所上传分块的 etag
                mutipartInfo.eTag = result!.eTag;
                mutipartInfo.partNumber = "1";
                // 保存起来用于最好完成上传时使用
                self.parts = [mutipartInfo];
            }
               
               
               
        }
        uploadPart.sendProcessBlock = {(bytesSent,totalBytesSent,totalBytesExpectedToSend) in
            //上传进度信息
            print("totalBytesSent:\(totalBytesSent) totalBytesExpectedToSend:\(totalBytesExpectedToSend)");
            
        }
        QCloudCOSXMLService.defaultCOSXML().uploadPart(uploadPart);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    /**
     * 查询存储桶（Bucket）中正在进行中的分块上传对象的方法.
     *
     * COS 支持查询 Bucket 中有哪些正在进行中的分块上传对象，单次请求操作最多列出 1000 个正在进行中的 分块上传对象.
     */
    func listParts() {
        
        //.cssg-snippet-body-start:[swift-list-parts]
        let req = QCloudListMultipartRequest.init();
        req.object = "exampleobject";
        req.bucket = "examplebucket-1250000000";
        //在初始化分块上传的响应中，会返回一个唯一的描述符（upload ID）
        req.uploadId = "exampleUploadId";
        if self.uploadId != nil {
            req.uploadId = self.uploadId!;
        }
        req.setFinish { (result, error) in
            if error != nil{
                print(error!);
            }else{
                //从 result 中获取已上传分块信息
                print(result!);
            }
               
               
               
        }
        
        QCloudCOSXMLService.defaultCOSXML().listMultipart(req);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    // 完成分片上传任务
    func completeMultiUpload() {

        
        //.cssg-snippet-body-start:[swift-complete-multi-upload]
        let  complete = QCloudCompleteMultipartUploadRequest.init();
        complete.bucket = "examplebucket-1250000000";
        complete.object = "exampleobject";
        //本次要查询的分块上传的 uploadId，可从初始化分块上传的请求结果 QCloudInitiateMultipartUploadResult 中得到
        complete.uploadId = "exampleUploadId";
        if self.uploadId != nil {
            complete.uploadId = self.uploadId!;
        }
        
        
        //已上传分块的信息
        let completeInfo = QCloudCompleteMultipartUploadInfo.init();
        if self.parts == nil {
            print("没有要完成的分块");
            return;
        }
        if self.parts != nil {
            completeInfo.parts = self.parts ?? [];
        }
        
        complete.parts = completeInfo;
        complete.setFinish { (result, error) in
            if error != nil{
                print(error!)
            }else{
                //从 result 中获取上传结果
                print(result!);
            }
               
               
               
        }
        QCloudCOSXMLService.defaultCOSXML().completeMultipartUpload(complete);
        
        //.cssg-snippet-body-end
        
          
    }
    
    
    func testMultiPartsUploadObject() {
        // 初始化分片上传
        self.initMultiUpload();
        // 列出所有未完成的分片上传任务
        self.listMultiUpload();
        // 上传一个分片
        self.uploadPart();
        // 列出已上传的分片
        self.listParts();
        // 完成分片上传任务
        self.completeMultiUpload();
    }
}