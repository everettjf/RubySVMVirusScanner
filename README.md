RubySVMVirusScanner
===================

# Environment

> gem install rb-libsvm

> gem install pedump

> gem install sqlite3


# Usage
- 可以通过下面的命令获取到存储imports和sections的数据库。

```
ruby rvsfetchiat.rb --health C:/Windows/System32
```
```
ruby rvsfetchiat.rb --virus E:/train_virus/files
```
```
ruby rvsfetchiat.rb --merge
```

- 通过下面的命令获取一个文件的属性

```
ruby rvsfetchiat.rb --file C:/Windows/System32/notepad.exe
```

### 训练模型
指定存储要训练的正常文件的文件夹和病毒文件的文件夹。

```
ruby rvsscan.rb --train /Users/everettjf/Virus/train/train_health /Users/everettjf/Virus/train/train_virus
```

### 测试模型

```
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/train_virus
```
```
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/train_health
```
```
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/test_virus
```
```
ruby rvsscan.rb --scan /Users/everettjf/Virus/train/test_health
```


