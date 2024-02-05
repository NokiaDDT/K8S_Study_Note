# Microsoft Word
## How to convert multiple doc into docx
https://www.pdnob.com/document/doc-to-docx.html

1. 開啟word，按下 `Alt +F11`，開啟 MS VB for Application
2. 選取 `Normal` -> `Module` -> 上方選項`插入` -> `模組`
3. 輸入下列程式碼
```

Sub TranslateDocIntoDocx()
    Dim objWordApplication As New Word.Application
    Dim objWordDocument As Word.Document
    Dim strFile As String
    Dim strFolder As String
    
    strFolder = "C:\Users\nokia_du\Desktop\2024_TaiShinBank\POC_Data2\"
    strFile = Dir(strFolder & "*.doc", vbNormal)
    
    While strFile <> ""
        With objWordApplication
            Set objWordDocument = .Documents.Open(FileName:=strFolder & strFile, AddToRecentFiles:=False, ReadOnly:=True, Visible:=False)
            
            With objWordDocument
                .SaveAs FileName:=strFolder & Replace(strFile, "doc", "docx"), FileFormat:=16
                .Close
            
            End With
        End With
        strFile = Dir()
    Wend
    
    Set objWordDocument = Nothing
    Set objWordApplication = Nothing
End Sub
```
注意`strFolder`要用反斜線結尾 \
4. 按下`F5`執行
