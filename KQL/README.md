# KQL Debug 速查（可直接 Copy/Paste）

下面这些查询主要用于把同一次请求/同一次 Function Invocation 的 `traces`（日志）和 `exceptions`（异常）快速串起来，方便定位错误。

## 1) 按 `operation_Id` + `InvocationId` 串起完整时间线（traces + exceptions）

用途：

- 把 `traces` 与 `exceptions` 合并后按时间排序，得到一次调用从开始到报错的完整链路。

需要你替换：

- `operation_Id`：同一条请求链路/调用链的标识
- `customDimensions['InvocationId']`：某次 Function 执行（Invocation）的标识

```kusto
union traces
| union exceptions
| where timestamp > ago(30d)
| where operation_Id == 'c259e48ef598c174a6fa805761d52af3'
| where customDimensions['InvocationId'] == '823efe9e-b36f-4397-89e8-0ce0bc6a4f13'
| order by timestamp asc
| project
    timestamp,
    message = iff(message != '', message, iff(innermostMessage != '', innermostMessage, customDimensions.['prop__{OriginalFormat}'])),
    logLevel = customDimensions.['LogLevel'],
    severityLevel
```

说明：

- `union traces | union exceptions`：把两张表拼在一起查。
- `project ... message = iff(...)`：优先用 `message`，否则用异常的 `innermostMessage`，再否则用结构化日志里常见的 `prop__{OriginalFormat}`。

## 2) 只看某次 Invocation 的异常（exceptions）

用途：

- 只关心报错内容时，用最短查询先把异常捞出来。

```kusto
exceptions
| where customDimensions['InvocationId'] == '823efe9e-b36f-4397-89e8-0ce0bc6a4f13'
```

## 3) 按 `cloud_RoleName` 查看某个服务/Function App 最近日志（traces + exceptions）

用途：

- 你不知道 `operation_Id`/`InvocationId`，但知道是哪个服务实例（Role）在报错时，先按 role 把最近 1 天的日志和异常扫一遍。

需要你替换：

- `cloud_RoleName`：例如 Function App 的名字（或对应角色名）

```kusto
traces
| union exceptions
| where timestamp > ago(1d)
| where cloud_RoleName == "<func-app-name-dev>"
| project
    timestamp,
    message,
    details,
    severityLevel
```

## 4) 常用投影模板：优先展示更“像错误”的 message（推荐搭配任意查询）

用途：

- 很多异常在 `outerMessage` 更直观；这行投影能让结果更好读。

把它接在你的查询末尾即可：

```kusto
| project timestamp, message = iff(message != '', message, outerMessage), logLevel = customDimensions.['LogLevel'], severityLevel
```
