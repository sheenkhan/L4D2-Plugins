stock void SetHealth(int client, int iHealth, float fTempHealth = 0.0, int iReviveCount = 0, int iGoingToDie = 0)
{
	int g_iOldHealth = GetEntProp(client, Prop_Data, "m_iHealth");

	// or GetClientHealth()
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	//SetEntityHealth(client, iHealth);
	//SetEntData(client, FindDataMapInfo(client, "m_iHealth"), iHealth, 4, true);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", iGoingToDie);
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
	
	if (iHealth > g_iOldHealth)
	{
		Event hEvent = CreateEvent("heal_success");
		if (hEvent != null)
		{
			hEvent.SetInt("userid", GetClientUserId(client));
			hEvent.SetInt("subject", GetClientUserId(client));
			hEvent.SetInt("health_restored", iHealth - g_iOldHealth);
			hEvent.Fire(true);
		}
	}
}