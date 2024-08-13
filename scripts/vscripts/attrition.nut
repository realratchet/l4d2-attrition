//-----------------------------------------------------
Msg("Activating Attrition mutation\n");

if ( !IsModelPrecached( "models/infected/hulk_dlc3.mdl" ) )
    PrecacheModel( "models/infected/hulk_dlc3.mdl" );

if ( !IsModelPrecached( "models/infected/witch_bride.mdl" ) )
    PrecacheModel( "models/infected/witch_bride.mdl" );

function OnGameEvent_player_first_spawn(params)
{
    local player = GetPlayerFromUserID(params["userid"])

    if (player == null || !player.IsPlayer() || player.GetZombieType() == 9)
        return

    switch(player.GetZombieType())
    {
        case 8: SpawnTankItems(player); break;
        case 7: break; // witch (not really called by this event but w/e)
        case 11: break; // bride witch (not really called by this event but w/e)
        default: SpawnSpecialItems(player);
    }
}

function SpawnTankItems(infected)
{
    if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    if(RandomInt(1, 10) > 9) { // spawn nothing
        // Msg("------------------------------\n")
        // Msg("ATTRITION STATE\n")
        // Msg("------------------------------\n")
        // Msg("MolotovSpawns: " + SessionState.MolotovSpawns + "\n")
        // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
        // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
        // Msg("------------------------------\n")
        return
    }


    if(RandomInt(0, 3) <= 1 && SessionState.MolotovSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_molotov", infected)
        SessionState.MolotovSpawns = SessionState.MolotovSpawns - 1
    } else if(SessionState.MedkitSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_first_aid_kit", infected)
        SessionState.MedkitSpawns = SessionState.MedkitSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("MolotovSpawns: " + SessionState.MolotovSpawns + "\n")
    // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("------------------------------\n")
}

function SpawnWitchItems(infected)
{
    if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("------------------------------\n")
}

function SpawnOnPointOrInfected(classname, infected)
{
    local container
    switch(classname)
    {
        case "weapon_pain_pills": container = ValidSpawns.PillSpawns; break;
        case "weapon_first_aid_kit": container = ValidSpawns.MedkitSpawns; break;
        case "weapon_pipe_bomb": container = ValidSpawns.PipeSpawns; break;
        case "weapon_molotov": container = ValidSpawns.MolotovSpawns; break;
        default:
            Msg("[ATTRITION] Error cannot spawn " + classname + "\n")
            return;
    }

    // Msg("[ATTRITION] Spawning reward: " + classname + "\n")

    if(!SpawnOnPoint(container, classname)) {
        local spawnTable = {
            origin = infected.GetOrigin(),
            // angles = infected.GetAngles().ToKVString()
        }

        SpawnEntityFromTable(classname, spawnTable)
        // Msg("[ATTRITION] No more free spawnpoints left '" + classname + "' spawned on infected instead.\n")
    }
}

function SpawnSpecialItems(infected)
{
    if(RandomInt(0, 2) <= 1) { // spawn nothing
        // Msg("------------------------------\n")
        // Msg("ATTRITION STATE\n")
        // Msg("------------------------------\n")
        // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
        // Msg("PipeSpawns: " + SessionState.PipeSpawns + "\n")
        // Msg("------------------------------\n")
        return
    }

    if(RandomInt(0, 2) <= 1 && SessionState.PipeSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pipe_bomb", infected)
        SessionState.PipeSpawns = SessionState.PipeSpawns - 1
    } else if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("PipeSpawns: " + SessionState.PipeSpawns + "\n")
    // Msg("------------------------------\n")
}

function OnGameEvent_finale_start( params )
{
    SessionState.IsFinale = true
}

function OnGameEvent_gauntlet_finale_start( params )
{
    SessionState.IsFinale = true
}

MutationState <-
{
    MolotovSpawns = 2
    Tier2Spawns = 2
    MedkitSpawns = 2
    PillSpawns = 5
    PipeSpawns = 3
    IsFinale = false
    TankSpawnDelay = 0
    NextTankIsSpecial = false
}

WeaponsTier2 <-
[
    "weapon_rifle",
    "weapon_hunting_rifle",
    "weapon_autoshotgun",
    "weapon_sniper_military",
    "weapon_shotgun_spas",
    "weapon_rifle_ak47",
    "weapon_rifle_desert",
    "tier2_any",
    "tier2_shotgun",
    "any_rifle",
    "any_sniper_rifle"
]

if (!Director.IsSessionStartMap())
{
    function PlayerSpawnDeadAfterTransition(userid)
    {
        local player = GetPlayerFromUserID(userid);
        if (!player)
            return;

        player.SetHealth(10);
        player.SetHealthBuffer(40);
    }

    function OnGameEvent_player_transitioned(params)
    {
        local player = GetPlayerFromUserID(params["userid"]);
        if (!player || !player.IsSurvivor())
            return;

        if (NetProps.GetPropInt(player, "m_lifeState") == 2)
            EntFire("worldspawn", "RunScriptCode", "g_ModeScript.PlayerSpawnDeadAfterTransition(" + params["userid"] + ")", 0.03);
    }
}

function OnGameEvent_defibrillator_used(params)
{
    local player = GetPlayerFromUserID(params["subject"]);
    if (!player)
        return;

    player.SetHealth(1);
    player.SetHealthBuffer(49);
}

function OnGameEvent_survivor_rescued(params)
{
    local player = GetPlayerFromUserID(params["victim"]);
    if (!player)
        return;

    player.SetHealth(1);
    player.SetHealthBuffer(49);
}

function OnTankDeath(infected)
{
    SessionState.MolotovSpawns = SessionState.MolotovSpawns + 0.5
    SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5
    SessionState.PillSpawns = SessionState.PillSpawns + 1

    local spawnTable = { origin = infected.GetOrigin(), angles = infected.GetAngles().ToKVString() }

    if(!SessionState.IsFinale && RandomInt(1, 10) <= 5)
        ZSpawn({ type = 11 })

    SpawnTankItems(infected) // tank lets you double dip
}

function OnWitchDeath(infected)
{
    SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5
    SessionState.PillSpawns = SessionState.PillSpawns + 1

    SpawnWitchItems(infected)
}

function OnSpecialDeath(infected)
{
    SessionState.PillSpawns = SessionState.PillSpawns + 0.25
    SessionState.PipeSpawns = SessionState.PipeSpawns + 0.5
}

function OnGameEvent_player_death(params)
{
    local victim = null
    local attacker = null
    local victimClass = null

    if ("userid" in params) victim = GetPlayerFromUserID(params["userid"]);
    else if ("entityid" in params) victim = EntIndexToHScript(params["entityid"]);

    if ("attacker" in params) attacker = GetPlayerFromUserID(params["attacker"]);
    else if ("attackerentid" in params) attacker = EntIndexToHScript(params["attackerentid"]);

    if (victim.GetClassname() != "infected")
    {
        if (victim.GetClassname() == "witch" || victim.GetZombieType() != 9 && attacker != null && attacker.IsPlayer())
        {
            if (attacker != null && attacker.GetZombieType() == 9)
            {
                if(victim.GetClassname() == "witch")
                    OnWitchDeath(victim)
                else {
                    switch (victim.GetZombieType()) {
                        case 8: // tank
                            OnTankDeath(victim)
                            break;
                        case 7: break
                        case 11: break
                        default: // si
                            OnSpecialDeath(victim)
                            break;
                    }
                }
            }
        }
    }
}

// function OnGameEvent_witch_spawn(params)
// {
//     local witch = EntIndexToHScript(params.witchid)
//     local health = 0

//     switch (Convars.GetStr("z_difficulty").tolower())
//     {
//         case "easy": health = 1000; break;
//         case "normal": health = 1500; break;
//         case "hard": health = 2000; break;
//         case "impossible": health = 2500; break;
//     }
//     witch.SetMaxHealth(health)
//     witch.SetHealth(health)
// }

function OnGameEvent_tank_spawn(params)
{
    local tank = EntIndexToHScript(params.tankid)
    local health = 0
    switch (Convars.GetStr("z_difficulty").tolower())
    {
        case "easy": health = 10000; break;
        case "normal": health = 15000; break;
        case "hard": health = 20000; break;
        case "impossible": health = 30000;  break;
    }

    if(SessionState.NextTankIsSpecial) {
        SessionState.NextTankIsSpecial = false

        switch (Convars.GetStr("z_difficulty").tolower())
        {
            case "easy": health = 5000; break;
            case "normal": health = 10000; break;
            case "hard": health = 15000; break;
            case "impossible": health = 20000;  break;
        }

        tank.SetModel("models/infected/hulk_dlc3.mdl")
    }

    tank.SetMaxHealth(health)
    tank.SetHealth(health)

    if(SessionState.IsFinale && Time() > SessionState.TankSpawnDelay) {
        SessionState.NextTankIsSpecial = true
        SessionState.TankSpawnDelay = Time() + 2 // prevent filling server with tanks
        ZSpawn({ type = 8 })
    }
}

function OnGameEvent_spawner_give_item(params)
{
    local ent = EntIndexToHScript(params.spawner)
    // Msg(ent.GetClassname() + "\n");
    // Msg(CNetPropManager + "\n");
    // Msg(NetProps + "\n");
    // Msg(NetProps.HasProp(ent, "m_weaponID") + "\n");
    ent.Kill();
}

function OnGameEvent_triggered_car_alarm( params )
{
    ZSpawn({ type = 8 })
}

ValidSpawns <-
{
    MolotovSpawns = [],
    PipeSpawns = [],
    PillSpawns = [],
    MedkitSpawns = [],
    tanks = []
}

function AddSpawn(container, ent)
{
    local flow = GetFlowDistanceForPosition(ent.GetOrigin())
    local spawnpoint = {
        flow = flow,
        used = false,
        spawnTable = {
            origin = ent.GetOrigin(),
            angles = ent.GetAngles().ToKVString()
        }
    }

    container.append(spawnpoint)
}

function SpawnOnPoint(container, classname)
{
    local validFlows = []
    local minFlow = Director.GetFurthestSurvivorFlow()

    foreach(sp in container)
    {
        if(sp.used || sp.flow < minFlow) continue

        validFlows.append(sp)
    }

    local validSpawnsLen = validFlows.len()

    if(validSpawnsLen == 0) return false

    local spawnpoint = validFlows[RandomInt(0, validSpawnsLen - 1)]

    SpawnEntityFromTable(classname, spawnpoint.spawnTable)
    spawnpoint.used = true

    return true
}

MobSpawns <-
{
    tanks = []
}

function FillTankSpawns()
{
    local tankSpawns = 2

    if(RandomInt(1, 3) > 3)
        tankSpawns = 3  # chance for three tanks

    if(Director.IsFirstMapInScenario())
        tankSpawns = tankSpawns - 1 # less tanks in first map

    for (local i = 0; i < tankSpawns; i = i + 1)
        MobSpawns.tanks.append({ flow = 25 * (i + 1) + RandomInt(-10, 10), used = false })
}

function TickTankSupport()
{
    if(Director.IsTankInPlay())
    {
        DirectorOptions.CommonLimit = 20
        DirectorOptions.MobMinSize = 10
        DirectorOptions.MobMaxSize = 20
        // Msg("[ATTRITION] Reducing number of commons\n")
    }
    else
    {
        DirectorOptions.CommonLimit = 50
        DirectorOptions.MobMinSize = 25
        DirectorOptions.MobMaxSize = 50
        // Msg("[ATTRITION] Restoring number of commons\n")
    }
}

function TickTankFlow()
{
    if(SessionState.IsFinale) // no extra tanks during finale
        return

    local flow = (Director.GetFurthestSurvivorFlow() / GetMaxFlowDistance()) * 100

    // Msg("[ATTRITION] Current flow " + flow + "\n")
    foreach(sp in MobSpawns.tanks)
    {
        // Msg("[ATTRITION] Tank spawn @ " + sp.flow + " | used: " + sp.used + "\n")
        if(sp.used || sp.flow > flow) continue

        ZSpawn({ type = 8 })
        sp.used = true
    }
}

function Update()
{
    TickTankSupport()
    TickTankFlow()


}

function LimitSpawnPoint(classnames, spawnKey)
{
    local ent

    foreach(classname in classnames)
    {
        while (ent = Entities.FindByClassname(ent, classname))
        {
            if (SessionState[spawnKey] < 1) {
                AddSpawn(ValidSpawns[spawnKey], ent)
                ent.Kill()
                continue
            }

            // Msg("[ATTRITION] " + spawnKey + ": " + SessionState[spawnKey] + "\n")
            SessionState[spawnKey] = SessionState[spawnKey] - 1;
        }
    }
}

function ReplaceAndLimitSpawnPoint(classnames, newClassname, spawnKey)
{
    local ent

    foreach(classname in classnames)
    {
        while (ent = Entities.FindByClassname(ent, classname))
            {
                if (SessionState.PillSpawns < 1) {
                    AddSpawn(ValidSpawns.PillSpawns, ent)
                    ent.Kill()
                    continue
                }

                local spawnTable = {
                    origin = ent.GetOrigin(),
                    angles = ent.GetAngles().ToKVString()
                }

                SpawnEntityFromTable(newClassname, spawnTable)
                ent.Kill()

                // Msg("[ATTRITION] " + spawnKey + "(" + classname + "): " + SessionState[spawnKey] + "\n")
                SessionState.PillSpawns = SessionState.PillSpawns - 1;
            }
    }
}

function ModifyWeaponSpawns()
{
    local ent

    while (ent = Entities.FindByClassname(ent, "weapon_spawn"))
    {
        NetProps.SetPropInt(ent, "m_itemCount", 1)
        NetProps.SetPropInt(ent, "m_spawnflags", NetProps.GetPropInt(ent, "m_spawnflags") & ~(4 | 8)) // remove infinite and absorb flags

        if(NetProps.GetPropString( ent, "m_iszWeaponToSpawn" ) == "any_primary") {
                if(ent.IsValid()) {
                    local weapon_selection
                    if(SessionState.Tier2Spawns < 1 || RandomInt(0, 2) <= 1) weapon_selection = "tier1_any"
                    else {
                        weapon_selection = "tier2_any"
                        SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1
                    }

                local spawnTable =
                {
                    origin = ent.GetOrigin(),
                    angles = ent.GetAngles().ToKVString(),
                    targetname = ent.GetName(),
                    count = 1,
                    spawnflags = NetProps.GetPropInt( ent, "m_spawnflags" ),
                    weapon_selection = weapon_selection,
                    spawn_without_director = 1
                }

                ent.Kill();
                SpawnEntityFromTable("weapon_spawn", spawnTable)
                continue
            }
        }

       if (!WeaponsTier2.find(NetProps.GetPropString( ent, "m_iszWeaponToSpawn" )))
            continue;

        if (SessionState.Tier2Spawns < 1) {
            ent.Kill()
            continue
        }

        SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1
    }
}

function OnGameEvent_round_start_post_nav(params) {
    FillTankSpawns()

    LimitSpawnPoint(["weapon_molotov", "weapon_molotov_spawn"], "MolotovSpawns")
    LimitSpawnPoint(["weapon_pipe_bomb", "weapon_pipe_bomb_spawn", "weapon_vomitjar", "weapon_vomitjar_spawn"], "PipeSpawns")
    LimitSpawnPoint(["weapon_first_aid_kit", "weapon_first_aid_kit_spawn"], "MedkitSpawns")
    LimitSpawnPoint(["weapon_pain_pills", "weapon_pain_pills_spawn"], "PillSpawns")

    ReplaceAndLimitSpawnPoint(["weapon_adrenaline", "weapon_adrenaline_spawn"], "weapon_pain_pills", "PillSpawns")
    ReplaceAndLimitSpawnPoint(["weapon_defibrillator", "weapon_defibrillator_spawn"], "weapon_first_aid_kit", "MedkitSpawns")

    ModifyWeaponSpawns()
    LimitSpawnPoint(WeaponsTier2, "Tier2Spawns")
}

DirectorOptions <-
{
    ActiveChallenge = 1

    SpecialRespawnInterval = 10
    SpecialInitialSpawnDelayMin = 10
    SpecialInitialSpawnDelayMax = 15
    ShouldAllowSpecialsWithTank = true

    DisallowThreatType = ZOMBIE_TANK

    HunterLimit = 4
    SmokerLimit = 3
    ChargerLimit = 1
    JockeyLimit = 1
    SpitterLimit = 1
    BoomerLimit = 1
    TankLimit = 3
    WitchLimit = 5
    WanderingZombieDensityModifier = 0.1
    CommonLimit = 50
    MobMinSize = 25
    MobMaxSize = 50

    // convert items that aren't useful
    weaponsToConvert =
    {
        // weapon_vomitjar = "weapon_pipe_bomb"
        // weapon_defibrillator = "weapon_first_aid_kit"
        weapon_pistol_magnum = "weapon_pistol"
        weapon_upgradepack_incendiary = "weapon_pain_pills"
        weapon_upgradepack_explosive = "weapon_pain_pills"
        // weapon_adrenaline = "weapon_pain_pills"
        // weapon_rifle_ak47 = "weapon_rifle"
        // weapon_smg_silenced = "weapon_smg"
        // weapon_shotgun_chrome = "weapon_pumpshotgun"
        // weapon_rifle_desert = "weapon_rifle"
        // weapon_sniper_military = "weapon_hunting_rifle"
        // weapon_shotgun_spas = "weapon_autoshotgun"
    }

    function ConvertWeaponSpawn(classname)
    {
        if (classname in weaponsToConvert) {
            Msg("[ATTRITION] Replaced spawn of " + classname + " with " + weaponsToConvert[classname] + "\n")
            return weaponsToConvert[classname];
        }

        return 0;
    }

    weaponsToRemove =
    {
        weapon_grenade_launcher = 0
        weapon_smg_mp5 = 0
        weapon_rifle_sg552 = 0
        weapon_sniper_awp = 0
        weapon_sniper_scout = 0
        weapon_rifle_m60 = 0
        weapon_melee = 0
        weapon_chainsaw = 0
        weapon_pistol_magnum = 0
        // weapon_smg_silenced = 0
        // weapon_shotgun_chrome = 0
        weapon_vomitjar = 0
        // weapon_rifle_ak47 = 0
        // weapon_shotgun_spas = 0
        // weapon_sniper_military = 0
        // weapon_rifle_desert = 0
        // weapon_upgradepack_explosive = 0
        // weapon_upgradepack_incendiary = 0
    }

    function AllowWeaponSpawn(classname)
    {
        if (classname in weaponsToRemove)
            return false;

        return true;
    }

    DefaultItems =
    [
        "pistol",
    ]

    function GetDefaultItem(idx)
    {
        if (idx < DefaultItems.len())
            return DefaultItems[idx];

        return 0;
    }
}
