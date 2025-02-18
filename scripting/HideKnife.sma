#include <amxmodx>
#include <hamsandwich>
#include <nvault>
#include <reapi>

new bool:g_bDebugMode;

new bool:g_playerHideKnife[MAX_PLAYERS + 1][TeamName];

new g_iVault;

public plugin_init() {
	register_plugin("Hideknife", "1.1", "ufame, OpenHNS"); // ufame (https://github.com/ufame/brohns/blob/master/server/src/scripts/hns/hns_hideknife.sma)

	RegisterSayCmd("hideknife", "showknife", "commandHideKnife", 0, "Show knife");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "knifeDeploy", 1);

	g_bDebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
}

public plugin_cfg() {
	g_iVault = nvault_open("hideknife");

	if (g_iVault == INVALID_HANDLE) {
		log_amx("Hideknife.sma: plugin_cfg:: can't open file ^"hideknife.vault^"!");
	}
}

public client_putinserver(id) {
	g_playerHideKnife[id][TEAM_TERRORIST] = false;
	g_playerHideKnife[id][TEAM_CT] = false;

	if (g_iVault != INVALID_HANDLE) {
		new szAuthID[32];
		get_user_authid(id, szAuthID, charsmax(szAuthID));

		new szData[32], iTimeStamp;

		if (nvault_lookup(g_iVault, szAuthID, szData, charsmax(szData), iTimeStamp)) {
			new szKnifeTT[3], szKnifeCT[3];

			parse(szData, szKnifeTT, charsmax(szKnifeTT), szKnifeCT, charsmax(szKnifeCT));

			g_playerHideKnife[id][TEAM_TERRORIST] = str_to_num(szKnifeTT) ? true : false;
			g_playerHideKnife[id][TEAM_CT] = str_to_num(szKnifeCT) ? true : false;

			if (g_bDebugMode) server_print("[Hideknife] Load %n: TT: %d, CT: %d.", id, g_playerHideKnife[id][TEAM_TERRORIST], g_playerHideKnife[id][TEAM_CT]);

			nvault_remove(g_iVault, szAuthID);
		}
	}
}

public client_disconnected(id) {
	if (g_iVault != INVALID_HANDLE) {
		new szAuthID[32];
		get_user_authid(id, szAuthID, charsmax(szAuthID));

		new szData[32];

		formatex(szData, charsmax(szData), "^"%d^" ^"%d^"", g_playerHideKnife[id][TEAM_TERRORIST], g_playerHideKnife[id][TEAM_CT]);

		if (g_bDebugMode) server_print("[Hideknife] Save %n: TT: %d, CT: %d.", id, g_playerHideKnife[id][TEAM_TERRORIST], g_playerHideKnife[id][TEAM_CT]);

		nvault_set(g_iVault, szAuthID, szData);
	}
	g_playerHideKnife[id][TEAM_TERRORIST] = false;
	g_playerHideKnife[id][TEAM_CT] = false;
}

public commandHideKnife(id) {
	new szMsg[64];
	new szMsgYesNo[16];

	formatex(szMsg, charsmax(szMsg), "Hide knife");
	new hMenu = menu_create(szMsg, "hideknifeHandler");

	formatex(szMsgYesNo, charsmax(szMsgYesNo), g_playerHideKnife[id][TEAM_TERRORIST] ? "Yes" : "No");
	formatex(szMsg, charsmax(szMsg), "Hide for \yTT \r%s", szMsgYesNo);
	menu_additem(hMenu, szMsg);

	formatex(szMsgYesNo, charsmax(szMsgYesNo), g_playerHideKnife[id][TEAM_CT] ? "Yes" : "No");
	formatex(szMsg, charsmax(szMsg), "Hide for \yCT \r%s", szMsgYesNo);
	menu_additem(hMenu, szMsg);

	menu_display(id, hMenu);

	return PLUGIN_HANDLED;
}

public hideknifeHandler(const id, const menu, const item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	menu_destroy(menu);

	new bool: hideKnife;
	new TeamName: hideTeam;

	switch (item) {
	case 0: {
		hideTeam = TEAM_TERRORIST;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];

		commandHideKnife(id);
	}
	case 1: {
		hideTeam = TEAM_CT;

		hideKnife = g_playerHideKnife[id][hideTeam] = !g_playerHideKnife[id][hideTeam];

		commandHideKnife(id);
	}
	}

	if (is_user_alive(id) && hideTeam == get_member(id, m_iTeam)) {
		new activeItem = get_member(id, m_pActiveItem);

		if (is_nullent(activeItem) || get_member(activeItem, m_iId) != WEAPON_KNIFE)
			return PLUGIN_HANDLED;

		set_entvar(id, var_viewmodel, hideKnife ? "" : "models/v_knife.mdl");
	}

	return PLUGIN_HANDLED;
}

public knifeDeploy(const entity) {
	new player = get_member(entity, m_pPlayer);
	new TeamName: team = get_member(player, m_iTeam);

	if (g_playerHideKnife[player][team])
		set_entvar(player, var_viewmodel, "");
}

stock RegisterSayCmd(const szCmd[], const szShort[], const szFunc[], flags = -1, szInfo[] = "") {
	new szTemp[65], szInfoLang[65];
	format(szInfoLang, 64, "%L", LANG_SERVER, szInfo);

	format(szTemp, 64, "say /%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szCmd);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say /%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "say .%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "/%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	format(szTemp, 64, "%s", szShort);
	register_clcmd(szTemp, szFunc, flags, szInfoLang);

	return 1;
}