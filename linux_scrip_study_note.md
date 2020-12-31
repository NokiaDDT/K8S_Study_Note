# SED (Stream Editor) 使用方法
## 問題說明
防毒軟體需要在/etc/network/interfaces進行設置，需要使用到 sed 指令，但是需要使用 1. 包含dns-nameservers開頭的字串 2. 但不包含MIS IP 的複數 sed 判斷來進行，這部份確實有許多難處。
其中一個問題是 sed 會針對檔案所有內容都進行套用，若用此思路會陷入死胡同。另一個是不熟悉 Regular Expression 的 Negative Lookbehind 語法，花了許多時間搞懂它，但最後發現 sed 不支援。

## interfaces 設定前內容如下：
```apacheconfig
auto lo
iface lo inet loopback

dns-nameservers 8.8.8.8 8.8.4.4
```
## interfaces 設定後內容如下：
```apacheconfig
auto lo
iface lo inet loopback

dns-nameservers 8.8.8.8 8.8.4.4 172.22.44.53 172.22.44.54
dns-search corpnet.asus 172.22.44.53 172.22.44.54
```

## 使用技巧
1. sed 可以使用 [!] 來進行 not，因此可以善用這個指令來控制sed的輸出
下列指令可以將非dns-nameservers開頭的line列出，搭配 `sed -n '/{pattern}/!p'` 這個指令可以印出我們所有不符合{pattern}的內容
```bash
sed -n '/^dns-nameservers.*/!p'
```
2. 一開始打算使用 Regular Expression 的 Negative Lookbehind 技巧來判斷包含dns-nameservers但不包含172.22.44.53的字串，後來發現sed不支援，只好改變方法。(參考 Reference #2, #3 & #4)

3. 研究發現 Sed脚本執行遵從下面簡單易記的順序：Read,Execute,Print,Repeat(讀取，執行，打印，重複)，簡稱 REPR 分析脚本執行順序：
- 讀取一行到模式空間(sed內部的一個臨時暫存區，用於存放讀取到的內容)
- 在模式空間中執行命令。如果使用了{ } 或 -e 指定了多個命令，sed將一次執行每個命令
- 打印模式空間的內容，然後清空模式空間
- 重複上述過程，直到文件結束

4. 根據第三點，我們使用兩個步驟來解析interfaces文件，先將非dns-nameservers開頭的內容搬移。這部份使用第1點技巧即可。

5. 然後我們根據第1點技巧與sed在模式空間中可以執行多個命令的特性，使用 `sed '/{pattern}/!d'`先將所有不符合的內容清空，這樣就可以避免其他內容套用後續的sed命令。
接著我們再用`sed -e '{script}' -e '{script}' filename`的技巧搭配，就可以解析出dns-nameservers開頭的字串是否有包含MIS IP的設定，避免多加設定。
最後使用 ```s/$/{new_pattern}/``` 這個技巧將我們需要的IP加到該行的最後
```bash
sed -e '/^dns-nameservers/!d' -e '/172.22.44.53/!s/$/ 172.22.44.53/' -e '/172.22.44.54/!s/$/ 172.22.44.54/' $CONFIG_BAK >> $CONFIG_ORIGIN
```

6. 最後使用 && || 指令來判斷重啟服務是否正常來決定後續流程。(參考 Reference #5)

## 完整script
[deep-security-networking-config-1231.sh](./deep-security-networking-config-1231.sh)

## Reference
1. [Sed & Awd 101 Hacks 中文版電子書](https://jimmysong.io/linux-practice/books/sed_and_awk_101_hacks_chinese_edition.pdf)
2. [Lookahead and Lookbehind Zero-Length Assertions](http://www.regular-expressions.info/lookaround.html)
3. [Excluding Matches With Regular Expressions](https://blog.codinghorror.com/excluding-matches-with-regular-expressions/)
4. [Does lookbehind work in sed?](https://stackoverflow.com/questions/26110266/does-lookbehind-work-in-sed)
5. [Linux 下的 &, &&, | 及 || 的用法](https://www.opencli.com/linux/linux-and-andand)
