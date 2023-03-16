#include <amxmodx>
#include <cstrike>
#include <reapi>

new g_iPlayerMoney[MAX_PLAYERS+1]

public plugin_init() {
	register_plugin("[API] Player Money", "0.0.1", "JustGo")

	set_msg_block(get_user_msgid("Money"), BLOCK_SET)
	register_event("ResetHUD", "EHook_ResetHUD", "be")
}

public plugin_natives() {
	register_native("Player_GetMoney", "Native_GetMoney")
	register_native("Player_SetMoney", "Native_SetMoney")
	register_native("Player_CanBuy", "Native_CanBuy")
	register_native("Player_Buy", "Native_Buy")
}

public Native_GetMoney(plugin_id, argc) {
	new pPlayer = get_param(1)
	return g_iPlayerMoney[pPlayer]
}

public Native_SetMoney(plugin_id, argc) {
	new pPlayer = get_param(1)
	new iAmount = get_param(2)
	g_iPlayerMoney[pPlayer] = iAmount
	cs_set_user_money(pPlayer, g_iPlayerMoney[pPlayer], 0)
	return true
}

public Native_CanBuy(plugin_id, argc) {
	new pPlayer = get_param(1)
	new iAmount = get_param(2)
	
	if (g_iPlayerMoney[pPlayer] < iAmount) {
		return false;
	}

	return true
}

public Native_Buy(plugin_id, argc) {
	new pPlayer = get_param(1)
	new iAmount = get_param(2)
	
	if (g_iPlayerMoney[pPlayer] < iAmount) {
		return false;
	}

	g_iPlayerMoney[pPlayer] -= iAmount
	cs_set_user_money(pPlayer, g_iPlayerMoney[pPlayer], 0)
	return true
}

public EHook_ResetHUD(pPlayer) {
	if (!is_user_connected(pPlayer)) return

	cs_set_user_money(pPlayer, g_iPlayerMoney[pPlayer], 0)
}

public client_disconnected(pPlayer) {
	g_iPlayerMoney[pPlayer] = 0
}