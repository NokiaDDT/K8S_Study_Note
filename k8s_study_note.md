# K8S_Study_Note

### 容器技術的基石 - CGROUP & NAMESPACE
[一篇搞懂容器技术的基石： cgroup](https://zhuanlan.zhihu.com/p/434731896) <br/>
[搞懂容器技术的基石： namespace （上）](https://moelove.info/2021/12/10/%E6%90%9E%E6%87%82%E5%AE%B9%E5%99%A8%E6%8A%80%E6%9C%AF%E7%9A%84%E5%9F%BA%E7%9F%B3-namespace-%E4%B8%8A/) <br/>
[搞懂容器技术的基石： namespace （下）](https://moelove.info/2021/12/13/%E6%90%9E%E6%87%82%E5%AE%B9%E5%99%A8%E6%8A%80%E6%9C%AF%E7%9A%84%E5%9F%BA%E7%9F%B3-namespace-%E4%B8%8B/) <br/>

### Access Modes
PV 可以透過 ReadWriteOnce(一個 node 可 read-write，可縮寫為 RWO), ReadOnlyMany(一個 node 可 write，多個 node 可 read-only，可縮寫為 ROX), ReadWriteMany(多個 node 可 read-write，可縮寫為 RWX) 三種存取模式提供掛載，但存取控制機制本身並非由 k8s 支援，而是由 PV resource provider 支援（例如上面的例子為 NFS，就可以支援 ReadWriteMany，但 Ceph RBD 則不行）。
> [Cinder只支援RWO](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)

### Mount Options
k8s cluster 管理者可以在建立 PV 時，指定額外的 mount option，並在 volume 實際被掛載時套用；但需要注意的是，這功能並不是所有的 volume type 都支援，而且每個 volume type 可用的 mount option 也不盡相同，若是在不支援 mount option 的 volume type 中使用 mount option，就會無法掛載成功。
> [Cinder有支援](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#mount-options)

### Pod 如何使用 PV ?
正確的繫結關係應該是 Pod <--> PVC <--> PV，所以已經成功與 PV 繫結的 PVC 是必要的。
此外，還有幾點觀念必須知道的：
- PVC 屬於 namespace level resource，因此 Pod 只能與同一個 namespace 中的 PVC 進行繫結
- PV 屬於 cluster level resource，但若要支援 ROX(ReadOnlyMany) or RWX(ReadWriteMany)，就只限於同一個 namespace 中的 PVC 才可以

### 如何撰寫可攜性高的 Storage Configuration ?
搞清楚上面 Pod, PVC, PV 相關概念後，若是真有弄清楚 k8s storage 的設計概念，就會大概有以下的概念：
- 並非每個 k8s cluster 都會有相同的 storage 設定
- 承上，這也是 storage class 會被設計出來的原因

因此要撰寫可攜性高的設定也就不是什麼太困難的事情，只要大概遵守以下幾個原則即可：
- 不要使用 volume，改用 PVC
- 不要包含 PV 的設定，因為在其他的 k8s cluster 很有可能會無法建立相同的 PV
- 給使用者指定 storage class (k8s 使用者應該知道有什麼 storage class 可用)，讓 PVC 使用 storage class
- 若使用者沒指定 storage class，那就應該會有 default storage class 的相關設定
- 若 PVC 一直處於無法與任何 PV 繫結的狀況，那就需要詢問 k8s cluster 管理者

PV/PVC關係圖
![PV/PVC關係圖](https://github.com/NokiaDDT/K8S_Study_Note/blob/main/k8s_volume-pvc.png)

## Reference
[ [Kubernetes] Persistent Volume (Claim) Overview ](https://godleon.github.io/blog/Kubernetes/k8s-PersistentVolume-Overview/)
