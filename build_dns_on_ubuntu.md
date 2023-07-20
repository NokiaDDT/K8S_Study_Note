# Build Local DNS Server on Ubuntu

## Install DNS Server
```
sudo apt-get install bind9 bind9-doc dnsutils
```

## Config DNS & Validation
### 設定DNS Server Options
主要DNS設定在以下檔案中，包含是否需要forward DNS request\
`sudo vi /etc/bind/named.options`
```
allow-query { localhost; LAN; }; // allow queries from localhost and 10.78.19.0-10.78.19.255
forwarders {
                8.8.8.8;
};
```
使用下列指令進行驗證\
`named-checkconf /etc/bind/named.conf.options`

### 設定正反解Zone (domain)
新增的zone則在這個檔案中設定，此設定檔中說明zone的正解與反解檔案在何處\
其中要注意的是反解的IP是反過來的，以下為例是10.78.19.0/24\
`sudo vi /etc/bind/named.conf.local`
```
zone "rancher.aes.test" IN { //define the forward zone
    type master;
    file "/etc/bind/db.rancher.aes.test";
};

zone "19.78.10.in-addr.arpa" IN { // define the reverse zone
    type master;
    file "/etc/bind/db.rancher.aes.test.rev";
};
```
使用下列指令進行驗證\
`named-checkconf /etc/bind/named.conf.local`

### 設定正解Zone內容
根據/etc/bind/named.conf.local的設定，新增`/etc/bind/db.rancher.aes.test`與`/etc/bind/db.rancher.aes.test.rev`這兩個檔案，
* 可分別以`/etc/bind/db.local`與`/etc/bind/db.127`當基礎進行編輯

`sudo vi /etc/bind/db.rancher.aes.test`
```
$TTL    604800
@       IN      SOA     rancher-nginx.rancher.aes.test. rancher-nginx.rancher.aes.test. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      rancher-nginx.rancher.aes.test.
rancher-nginx.rancher.aes.test. IN A 10.78.19.58
rancher.aes.test. IN A 10.78.19.58
```
使用下列指令進行驗證\
`named-checkzone rancher.aes.test /etc/bind/db.rancher.aes.test`

### 設定反解Zone內容
`sudo vi /etc/bind/db.rancher.aes.test.rev`
```
$TTL    604800
@       IN      SOA     rancher-nginx.rancher.aes.test. rancher-nginx.rancher.aes.test. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      rancher-nginx.rancher.aes.test.
58      IN      PTR     rancher.aes.test.
```
使用下列指令進行驗證\
`named-checkzone 10.78.19.58 /etc/bind/db.rancher.aes.test.rev`

\* 上述檔案中的FQDN要注意以句點(.)為結尾才算完整的FQDN，否則會被判斷為hostname



## Start/Restart DNS
上述檔案設定好之後即可重啟DNS服務
```
sudo systemctl start bind9
sudo systemctl restart bind9
sudo systemctl status bind9
```

## Using Specific DNS & Flush DNS Cache
接下來即可在想要測試的主機上面，指定DNS Server，驗證是否可以解析設定的網域名稱。\
編輯`/etc/systemd/resolved.conf`，在`DNS=`之後加入上述DNS Server IP，若有多個則使用空白分開。
`sudo vi /etc/systemd/resolved.conf`
```
[Resolve]
DNS=DNS_IP_1 DNS_IP_2 DNS_IP_3
```
設定完之後執行下列指令即可生效
```
sudo systemctl daemon-reload
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved
```

\* 有時候DNS會有cache，可使用以下指令清除
```
sudo systemd-resolve --flush-caches
sudo systemctl restart systemd-resolved
```

則可以使用以下指令確認快取是否清除
```
sudo systemd-resolve --statistics
```

最後即可使用 Dig / Host / NSLookup 等指令進行網域驗證

`$ dig rancher.aes.test`
```
; <<>> DiG 9.16.1-Ubuntu <<>> rancher.aes.test
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60656
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;rancher.aes.test.              IN      A

;; ANSWER SECTION:
rancher.aes.test.       604800  IN      A       10.78.19.58

;; Query time: 0 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Thu Jul 20 09:53:29 UTC 2023
;; MSG SIZE  rcvd: 61
```

`$ host -a rancher.aes.test`
```
Trying "rancher.aes.test"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10527
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;rancher.aes.test.              IN      ANY

;; ANSWER SECTION:
rancher.aes.test.       604800  IN      SOA     rancher-nginx.rancher.aes.test. rancher-nginx.rancher.aes.test. 3 604800 86400 2419200 604800
rancher.aes.test.       604800  IN      NS      rancher-nginx.rancher.aes.test.
rancher.aes.test.       604800  IN      A       10.78.19.58

Received 114 bytes from 127.0.0.53#53 in 0 ms
```

`$ nslookup rancher.aes.test`
```
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
Name:   rancher.aes.test
Address: 10.78.19.58
```

# Reference
[鳥哥 - 第十九章、主機名稱控制者： DNS 伺服器](https://linux.vbird.org/linux_server/centos6/0350dns.php#DNS_resolver)\
[卡斯伯's blog - 自建 Name Server](https://www.casper.tw/dns/2019/04/25/custom_name_server/)\
[How to Install and Configure a Private BIND DNS Server on Ubuntu 22.04?](https://www.cherryservers.com/blog/how-to-install-and-configure-a-private-bind-dns-server-on-ubuntu-22-04)\
[Ubuntu 18.04 設定 DNS](https://roychou121.github.io/2020/07/15/ubuntu-dns/)\
[Flush DNS Cache on Ubuntu](https://linuxhint.com/flush_dns_cache_ubuntu/)\
