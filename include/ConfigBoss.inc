#pragma semicolon 1

#include <vsh2>

#define CHARACTER_CONFIG_FILE_PATH "configs/saxton_hale/boss_cfgs/configCharacters.cfg"

#define MINIMAL_STREAK_FOR_SPREE 3
#define DEFAULT_SPEED 100.0
#define DEFAULT_MAX_SPEED 340.0
#define DEFAULT_RAGE_RADIUS 300.0

// ability callback types
enum AbilityCallbackType {
    OnChargeAbility = 0,
    OnRageAbility
};

typeset CBAbilityHookCB {
    function void (const VSH2Player player, const ConfigMap bossConfig);
    function Action (const VSH2Player player, const ConfigMap bossConfig);
};

native bool ConfigBossHookAbility(const AbilityCallbackType callbackType, CBAbilityHookCB callback);