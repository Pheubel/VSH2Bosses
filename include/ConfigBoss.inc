#if !defined(CONFIG_BOSS_INC)
#define CONFIG_BOSS_INC

#pragma semicolon 1

#include <vsh2>
#include "include/VSH2Utils.inc"

#define MAX_ABILITY_NAME_SIZE 32
#define MAX_ABILITY_PLUGIN_NAME 64

#define MINIMAL_STREAK_FOR_SPREE 3
#define DEFAULT_SPEED 100.0
#define DEFAULT_MAX_SPEED 340.0
#define DEFAULT_RAGE_RADIUS 300.0
#define DEFAULT_CHARGE_TIME 1.0
#define DEFAULT_CHARGE_COOLDOWN -100.0

#define Register_Charge_Ability public void RegisterChargeAbility(int abilitySectionIndex)
#define Register_Rage_Ability public void RegisterRageAbility(int abilitySectionIndex)
#define Register_On_Life_Lost_Ability public void RegisterOnLifeLostAbility(int abilitySectionIndex)

#define GetChargeAbilitySection(%1) %1.GetSection(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY).GetIntSection(abilitySectionIndex)
#define GetRageAbilitySection(%1) %1.GetSection(VSH_DEFAULT_SELECTOR_RAGE_ABILITY).GetIntSection(abilitySectionIndex)
#define GetOnLifeLostAbilitySection(%1) %1.GetSection(VSH_DEFAULT_SELECTOR_LIFE_LOST_ABILITY).GetIntSection(abilitySectionIndex)

// event callback types
enum CallbackType {
    OnChargeAbility = 0,
    OnRageAbility,
    OnLifeLost
};

typeset CBEventHookCB {
    // OnChargeAbility
    // OnRageAbility
    function void (const VSH2Player bossPlayer);

    // OnLifeLost
    function void (const VSH2Player bossPlayer, const VSH2Player attacker);
};

native bool ConfigBossHookAbility(const CallbackType callbackType, CBEventHookCB callback);
native bool IsConfigBoss(VSH2Player bossPlayer);
native ConfigMap CloneBossConfigMap();

#endif