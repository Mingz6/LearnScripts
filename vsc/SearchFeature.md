# VS Code 搜索速记（最常用 2 个）

## 1) 找文件并打开

- `Cmd+P`
- 输入文件名/路径片段回车打开

## 2) 跨文件搜内容

- `Cmd+Shift+F`
- 需要正则时：点搜索框右侧 `.*`

### AND 搜索（同一行同时包含多个词）

通用模板：

```
(?=.*A)(?=.*B)
```

例子：TableName + Word

```
(?=.*\[<TableName>\])(?=.*<Word>)
```

例子：RelationshipTypeId + 41

```
(?=.*RelationshipTypeId)(?=.*41)
```
