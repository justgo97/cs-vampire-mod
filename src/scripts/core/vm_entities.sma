#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <vm_main>

public plugin_init() {
	register_plugin("[VM] Entities", VM_VERSION, "JustGo")

	RegisterHamPlayer(Ham_TakeHealth, "HHook_PlayerTakeHealth")
	RegisterHam(Ham_Use, "game_player_equip", "HHook_UseEquip")
	RegisterHam(Ham_Touch, "armoury_entity", "HHook_TouchArmoury")
	RegisterHam(Ham_Touch, "weaponbox", "HHook_TouchWeaponbox")
	RegisterHam(Ham_Touch, "trigger_gravity", "HHook_TouchTrigger")
}

public HHook_PlayerTakeHealth(pPlayer) {
	return HAM_SUPERCEDE;
}

public HHook_UseEquip(button, pPlayer)
{
	return HAM_SUPERCEDE;
}

public HHook_TouchArmoury(ent, pPlayer) {
	if (!ShouldBlock(pPlayer)) return HAM_IGNORED

	return HAM_SUPERCEDE;
}

public HHook_TouchWeaponbox(ent, pPlayer) {
	if (!ShouldBlock(pPlayer)) return HAM_IGNORED

	return HAM_SUPERCEDE;
}

public HHook_TouchTrigger(ent, pPlayer) {
	return HAM_SUPERCEDE;
}

bool:ShouldBlock(pPlayer) {
	if (!is_user_alive(pPlayer)) return false;

	if (get_member(pPlayer, m_iTeam) == TEAM_TERRORIST) return true

	return false;
}