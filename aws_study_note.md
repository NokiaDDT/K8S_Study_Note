# AWS_Study_Note

### How to access AWS with MFA auth
AWS 設定 MFA 之後，任何界面操作都需要進行 MFA 認證。
##### 如使用 AWS Console，在登入的時候就需要題供 MFA code。
> 此部份依照網頁畫面操作即可

##### 如使用 AWS CLI，則必須透過 aws sts get-session-token 指令來獲得暫時性 token。
透過 STS get-session-token 指令，其中參數 serial-number 指的是 MFA 裝置 resouce ID，通常都是像這樣的格式。 arn:aws:iam::{accountID}:mfa/{iamID}。參數 token-code就是 MFA 認證碼。
> $ aws sts get-session-token --serial-number arn-of-the-mfa-device --token-code code-from-token

上述指令會獲得一個12小時的證書，類似：
```{
    "Credentials": {
        "SecretAccessKey": "secret-access-key",
        "SessionToken": "temporary-session-token",
        "Expiration": "expiration-date-time",
        "AccessKeyId": "access-key-id"
    }
}
```
獲得上述證書之後，則可以設定 Linux 環境變數來使用 AWS CLI。
> export AWS_ACCESS_KEY_ID=example-access-key-as-in-previous-output

> export AWS_SECRET_ACCESS_KEY=example-secret-access-key-as-in-previous-output

> export AWS_SESSION_TOKEN=example-session-token-as-in-previous-output

##### 如使用 AWS API，則必須套過 sts get-session-token API來獲得暫時性 token。

##### 如使用 S3 Browser，則必須在建立帳號的時候，選擇 Account Type 為：AWS S3 (Credentials from AWS Config or Credential file)

### Reference
[設定受 MFA 保護的 API 存取](https://docs.aws.amazon.com/zh_tw/IAM/latest/UserGuide/id_credentials_mfa_configure-api-require.html)

[How do I use an MFA token to authenticate access to my AWS resources through the AWS CLI?](https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/)

[AWS STS JavaScript SDK](https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/STS.html#getSessionToken-property)

[S3 Browser:  AWS Credentials from AWS Config or Crendential file](https://s3browser.com/aws-credentials-from-config-file.aspx)

### How to use StorageClass on EKS
基本概念請參考 [Storage Classes](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)，目前版本的 EKS 已經內建設定 GP2 為預設 Storage Class。
流程為 1. 確認 Storage Class 設定完成 2. 建立 PVC 3. 確認 EBS 自動產生 Volume，詳細內容請參考[[Day28] k8s應用篇（二）：EBS和EFS的使用](https://ithelp.ithome.com.tw/articles/10227675)
下列為 PVC 內容
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  labels:
    app: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    app: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```
準備好 pvc.yaml之後，使用下列指令進行 apply
> $kubectl apply -f pvcs.yaml -n ns-eks

> persistentvolumeclaim/mysql-pv-claim created

> persistentvolumeclaim/wp-pv-claim created

另外完成後記得要到  EC2 -> EBS -> Volumes 中將所產生的 Volume 刪除。

### Reference
[Storage Classes](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)

[[Day28] k8s應用篇（二）：EBS和EFS的使用](https://ithelp.ithome.com.tw/articles/10227675)
[]()
[]()
