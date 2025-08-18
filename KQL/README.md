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


exceptions
| where customDimensions['InvocationId'] == '823efe9e-b36f-4397-89e8-0ce0bc6a4f13'


traces
| union exceptions
| where timestamp > ago(1d)
| where cloud_RoleName == "<func-app-name-dev>"
| project
    timestamp,
    message,
    details,
    severityLevel