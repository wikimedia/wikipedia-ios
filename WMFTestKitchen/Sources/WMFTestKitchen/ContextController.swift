import Foundation

class ContextController {

    func enrichEvent(_ event: Event, streamConfig: StreamConfig) {
        guard streamConfig.hasRequestedContextValuesConfig() else { return }

        let requestedFromConfig = streamConfig.producerConfig?.metricsPlatformClientConfig?.requestedValues ?? []
        var requestedValues = Set(requestedFromConfig)
        ContextValue.requiredProperties.forEach { requestedValues.insert($0) }

        let filteredData = filterClientData(event.clientData, requestedValues: requestedValues)
        event.applyClientData(filteredData)
    }

    private func filterClientData(_ clientData: ClientData, requestedValues: Set<String>) -> ClientData {
        var newAgent = AgentData()
        var newMediawiki = MediawikiData()
        var newPerformer = PerformerData()

        for value in requestedValues {
            switch value {
            case ContextValue.agentAppInstallId: newAgent.appInstallId = clientData.agentData?.appInstallId
            case ContextValue.agentClientPlatform: newAgent.clientPlatform = clientData.agentData?.clientPlatform
            case ContextValue.agentClientPlatformFamily: newAgent.clientPlatformFamily = clientData.agentData?.clientPlatformFamily
            case ContextValue.agentAppFlavor: newAgent.appFlavor = clientData.agentData?.appFlavor
            case ContextValue.agentAppTheme: newAgent.appTheme = clientData.agentData?.appTheme
            case ContextValue.agentAppVersion: newAgent.appVersion = clientData.agentData?.appVersion
            case ContextValue.agentAppVersionName: newAgent.appVersionName = clientData.agentData?.appVersionName
            case ContextValue.agentDeviceFamily: newAgent.deviceFamily = clientData.agentData?.deviceFamily
            case ContextValue.agentDeviceLanguage: newAgent.deviceLanguage = clientData.agentData?.deviceLanguage
            case ContextValue.agentReleaseStatus: newAgent.releaseStatus = clientData.agentData?.releaseStatus
            case ContextValue.mediawikiDatabase: newMediawiki.database = clientData.mediawikiData?.database
            case ContextValue.performerId: newPerformer.id = clientData.performerData?.id
            case ContextValue.performerName: newPerformer.name = clientData.performerData?.name
            case ContextValue.performerIsLoggedIn: newPerformer.isLoggedIn = clientData.performerData?.isLoggedIn
            case ContextValue.performerIsTemp: newPerformer.isTemp = clientData.performerData?.isTemp
            case ContextValue.performerSessionId: newPerformer.sessionId = clientData.performerData?.sessionId
            case ContextValue.performerPageviewId: newPerformer.pageviewId = clientData.performerData?.pageviewId
            case ContextValue.performerGroups: newPerformer.groups = clientData.performerData?.groups
            case ContextValue.performerLanguageGroups:
                var languageGroups = clientData.performerData?.languageGroups
                if let lg = languageGroups, lg.count > 255 {
                    languageGroups = String(lg.prefix(255))
                }
                newPerformer.languageGroups = languageGroups
            case ContextValue.performerLanguagePrimary: newPerformer.languagePrimary = clientData.performerData?.languagePrimary
            case ContextValue.performerRegistrationDt: newPerformer.registrationDt = clientData.performerData?.registrationDt
            default: break
            }
        }

        return ClientData(agentData: newAgent, mediawikiData: newMediawiki, performerData: newPerformer)
    }
}
