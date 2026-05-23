// Python アプリログを Application Insights に送信するためのリソース一式。
// 構成: Log Analytics Workspace / Application Insights (Workspace-based, DisableLocalAuth=true)
//       / Monitoring Metrics Publisher ロール割当

// ----- パラメータ -----

@description('リソースのリージョン')
param location string = resourceGroup().location

@description('ロール付与先のプリンシパル ID')
param principalId string

@description('プリンシパル種別（CI/CD では ServicePrincipal）')
@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
param principalType string = 'User'

@description('リソース名のサフィックス（重複回避用）')
param resourceNameSuffix string = uniqueString(resourceGroup().id)

@description('Log Analytics データ保持期間（日）')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// ----- Log Analytics Workspace -----
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${resourceNameSuffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ----- Application Insights -----
// DisableLocalAuth=true で API キー方式を無効化し、Entra ID 認証を強制する。
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourceNameSuffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    DisableLocalAuth: true
    IngestionMode: 'LogAnalytics'
  }
}

// ----- ロール割当: Monitoring Metrics Publisher（テレメトリ書き込み用） -----
var monitoringMetricsPublisherRoleId = '3913510d-42f4-4e42-8a64-420c390055eb'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appInsights
  name: guid(appInsights.id, principalId, monitoringMetricsPublisherRoleId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleId)
  }
}

// ----- 出力 -----
#disable-next-line outputs-should-not-contain-secrets
output connectionString string = appInsights.properties.ConnectionString
output appInsightsName string = appInsights.name
output logAnalyticsWorkspaceName string = logAnalytics.name
