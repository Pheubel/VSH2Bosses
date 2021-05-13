#pragma semicolon 1

#include <vsh2>

#define MAX_ABILITY_NAME_SIZE 32
#define MAX_ABILITY_PLUGIN_NAME 64

#define MINIMAL_STREAK_FOR_SPREE 3
#define DEFAULT_SPEED 100.0
#define DEFAULT_MAX_SPEED 340.0
#define DEFAULT_RAGE_RADIUS 300.0

// event callback types
enum CallbackType {
    OnChargeAbility = 0,
    OnRageAbility,
    OnLifeLost
};

typeset CBEventHookCB {
    // OnChargeAbility
    // OnRageAbility
    function void (const VSH2Player bossPlayer, const ConfigMap bossConfig);

    // OnLifeLost
    function void (const VSH2Player bossPlayer, const VSH2Player attacker, const ConfigMap bossConfig);
};

native bool ConfigBossHookAbility(const CallbackType callbackType, CBEventHookCB callback);
native bool IsConfigBoss(VSH2Player bossPlayer);