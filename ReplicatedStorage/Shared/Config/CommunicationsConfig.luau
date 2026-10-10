--!strict

local CommunicationsConfig = {}
CommunicationsConfig.DiplomaticMaxDistance = 2
CommunicationsConfig.HistoryLimit = 80
CommunicationsConfig.Help = {
	diplomatic = "Public political communication with nearby realms. Messages reach rulers within realm-graph distance 2. Audience may differ between rulers.",
	council = "Private communication between a ruler and their direct subjects. Geographic distance does not restrict Council communication.",
	alliance = "Private communication between the rulers participating in this specific Alliance. Subjects and NAP partners do not receive these messages.",
	direct = "Private 1:1 communication with a neighboring ruler. Realms must currently share a border for normal communication.",
}
return CommunicationsConfig
