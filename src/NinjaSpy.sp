#pragma semicolon 1

#include <vsh2>
#include "include/VSH2Utils.inc"
#include "include/ItemAttributes.inc"
#include "include/ItemDefinitions.inc"

int BossId;
VSH2CVars VSH_CVars;
ConfigMap BossConfig;
VSH2GameMode vsh2_gm;

// Set up the Ninja Spy add-on after the VSH2 library has been added.
public void OnLibraryAdded(const char[] name) {
    if( StrEqual(name, "VSH2") ) {
        VSH_GET_CVARS(VSH_CVars);
        BossId = VSH2_RegisterPlugin("VSH_Ninja_Spy");
        BossConfig = new ConfigMap("configs/saxton_hale/boss_cfgs/NinjaSpy.cfg");
        LoadHooks();
    }
}

// Load all hooks used by the Ninja Spy boss.
void LoadHooks() {
    if( !VSH2_HookEx(OnBossMenu, HandleOnBossMenu) ) {
        LogError("Error loading OnBossMenu forwards for Ninja Spy subplugin.");
    }

    if ( !VSH2_HookEx(OnBossSelected, HandleOnBossSelected)) {
        LogError("Error loading OnBossSelected forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossInitialized, HandleOnBossInitialized)) {
        LogError("Error loading OnBossInitialized forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossEquipped, HandleOnBossEquipped)) {
        LogError("Error loading OnBossEquipped forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossPlayIntro, HandleOnBossPlayIntro)) {
        LogError("Error loading OnBossPlayIntro forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerKilled, HandleOnPlayerKilled)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerHurt, HandleOnPayerHurt)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerAirblasted, HandleOnPlayerAirblasted)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossJarated, HandleOnBossJarated)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossThink, HandleOnBossThink)) {
        LogError("Error loading OnBossThink forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossMedicCall, HandleOnBossMedicCall)) {
        LogError("Error loading OnBossMedicCall forwards for Ninja Spy subplugin.");
    }
}

void HandleOnBossMenu(Menu& menu) {
    AddBossToMenuFromConfig(menu, BossId, BossConfig);
}

void HandleOnBossSelected(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetPanelMessageFromConfig(player, BossConfig);
}

void HandleOnBossInitialized(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetEntProp(player.index, Prop_Send, "m_iClass", view_as<int>(TFClass_Spy));
}

void HandleOnBossEquipped(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetPlayerNameToBossFromConfig(player, BossConfig, VSH_DEFAULT_SELECTOR_NAME);
    player.RemoveAllItems();

    int attributeLenght = BossConfig.GetSize(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES);
    char[] attributeString = new char[attributeLenght];
    BossConfig.Get(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES, attributeString, attributeLenght);

    int wep = player.SpawnWeapon(TF_WEAPON_CLASS_SNIPER_MELEE_THE_SHAHANSHAH, TF_WEAPON_ID_SNIPER_MELEE_THE_SHAHANSHAH, 100, 5, attributeString);
    SetEntPropEnt(player.index, Prop_Send, "m_hActiveWeapon", wep);
}

void HandleOnBossPlayIntro(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_INTROS, VSH2_VOICE_INTRO);
}

void HandleOnPlayerKilled(const VSH2Player attacker, const VSH2Player victim, Event event) {
    if( !IsBossType(attacker, BossId)) {
        return;
    }

    int streak = HandleKillingSpree(attacker);

    if (vsh2_gm.iLivingReds != 1) {
        if(streak == 3) {
            PlayRandomSoundFromConfigSelector(attacker, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_SPREE, VSH2_VOICE_SPREE);
        }
        else {
            PlayRandomClassSoundFromConfigSelector(attacker, victim.GetTFClass(), BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_KILL_CLASS, VSH2_VOICE_SPREE);
        }
    }
}

void HandleOnPayerHurt(const VSH2Player attacker, const VSH2Player victim, Event event) {
    VSH_DEFAULT_CODE_ON_PLAYER_HURT(victim, BossId, event);
}

void HandleOnPlayerAirblasted(const VSH2Player airblaster, const VSH2Player airblasted, Event event) {
    VSH_DEFAULT_CODE_ON_PLAYER_AIRBLASTED(airblasted, BossId, VSH_CVars);
}

void HandleOnBossJarated(const VSH2Player victim, const VSH2Player thrower) {
    VSH_DEFAULT_CODE_ON_BOSS_JARATED(victim, BossId, VSH_CVars)
}

void HandleOnBossThink(const VSH2Player player)
{
    int client = player.index;
    if( !IsBossType(player, BossId) || !IsPlayerAlive(client)) {
        return;
    }

    player.SpeedThink(340.0);
    player.GlowThink(0.1);
    if( player.SuperJumpThink(2.5, 25.0) ) {
        PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_SUPER_JUMP, VSH2_VOICE_ABILITY);
        player.SuperJump(player.GetPropFloat("flCharge"), -100.0);
    }

    if( OnlyScoutsLeft(VSH2Team_Red) ) {
        player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + VSH_CVars.scout_rage_gen.FloatValue);
    }

    player.WeighDownThink(2.0, 0.1);

    /// hud code
    SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
    Handle hud = vsh2_gm.hHUD;
    float jmp = player.GetPropFloat("flCharge");
    float rage = player.GetPropFloat("flRAGE");
    if( rage >= 100.0 ) {
        ShowSyncHudText(client, hud, "Jump: %i%% | Rage: FULL - Call Medic (default: E) to activate", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4);
    }
    else {
        ShowSyncHudText(client, hud, "Jump: %i%% | Rage: %0.1f", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4, rage);
    }
}

void HandleOnBossMedicCall(const VSH2Player player)
{
    if( !IsBossType(player, BossId) || player.GetPropFloat("flRAGE") < 100.0) {
        return;
    }

    /// use ConfigMap to set how large the rage radius is!
    float radius = 300.0; /// in case of failure, default value!
    BossConfig.GetFloat(VSH_DEFAULT_SELECTOR_RAGE_DISTANCE, radius);

    player.DoGenericStun(radius);
    VSH2Player[] players = new VSH2Player[MaxClients];
    int in_range = player.GetPlayersInRange(players, radius);
    for( int i; i < in_range; i++ ) {
        if( players[i].bIsBoss || players[i].bIsMinion )
            continue;

        /// do a distance based thing here.
    }

    PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_RAGE, VSH2_VOICE_RAGE);
    player.SetPropFloat("flRAGE", 0.0);
}