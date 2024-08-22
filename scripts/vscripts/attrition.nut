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
        return
    }

    if(RandomInt(0, 3) <= 1 && SessionState.MolotovSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_molotov", infected)
        SessionState.MolotovSpawns = SessionState.MolotovSpawns - 1
    } else if(SessionState.MedkitSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_first_aid_kit", infected)
        SessionState.MedkitSpawns = SessionState.MedkitSpawns - 1
    }
}

function SpawnWitchItems(infected)
{
    if(SessionState.PillSpawns < 1) return;

    SpawnOnPointOrInfected("weapon_pain_pills", infected)
    SessionState.PillSpawns = SessionState.PillSpawns - 1
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

    if(!SpawnOnPoint(container, classname)) {
        local spawnTable = {
            origin = infected.GetOrigin(),
            angles = infected.GetAngles().ToKVString()
        }

        SpawnEntityFromTable(classname, spawnTable)
        DevPrint("\x03 [DEV] Spawning reward " + "\x04" + classname + "\x03" + " at position " + "\x04" + spawnTable.origin + "\x03" + ".")
    }
}

function SpawnSpecialItems(infected)
{
    if(RandomInt(0, 2) <= 1) { // spawn nothing
        return
    }

    if(RandomInt(0, 2) <= 1 && SessionState.PipeSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pipe_bomb", infected)
        SessionState.PipeSpawns = SessionState.PipeSpawns - 1
    } else if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }
}

function OnGameEvent_finale_start( params )
{
    SessionState.IsFinale = true
}

function OnGameEvent_gauntlet_finale_start( params )
{
    SessionState.IsFinale = true
}

InitialState <-
{
    MolotovSpawns = 2
    Tier2Spawns = 2
    MedkitSpawns = 2
    PillSpawns = 5
    PipeSpawns = 3
}

MutationState <-
{
    DevMode = false
    DevSaferoomExit = false
    DevTicks = 0
    MolotovSpawns = InitialState.MolotovSpawns
    Tier2Spawns = InitialState.Tier2Spawns
    MedkitSpawns = InitialState.MedkitSpawns
    PillSpawns = InitialState.PillSpawns
    PipeSpawns = InitialState.PipeSpawns
    IsFinale = false
    TankSpawnDelay = 0
    NextTankIsSpecial = false
    FlowTank = { isSpawned = false, inPlay = false, playedMegaMobSound = false, flowMin = 0, flowMax = 0 }
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

function OnGameEvent_map_transition(params)
{
    SaveTable("savedState", {
        DevMode = SessionState.DevMode,
        MolotovSpawns = SessionState.MolotovSpawns,
        MedkitSpawns = SessionState.MedkitSpawns,
        PillSpawns = SessionState.PillSpawns,
        PipeSpawns = SessionState.PipeSpawns,
    })
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

    if(!SessionState.IsFinale && RandomInt(1, 10) <= 5) {
        ZSpawn({ type = 11 })
        DevPrint("\x03" + "[DEV] Killed " + "\x04" + "Tank" + "\x03" + " spawned " + "\x04" + "Witch Bride" + "\x03" + " for punishment.")
    }

    if(!Director.IsTankInPlay() && SessionState.FlowTank.inPlay || SessionState.FlowTank.isSpawned) {
        SessionState.FlowTank.isSpawned = false
        SessionState.FlowTank.inPlay = false
        DevPrint("\x03" + "[DEV] " + "\x04" + "Tank" + "\x03" + " no longer in play, restoring commons.")
    }

    DevPrintRewards("Tank", ["MedkitSpawns", "MolotovSpawns", "PillSpawns"])

    SpawnTankItems(infected) // tank lets you double dip
}

function DevPrintRewards(type, rewards)
{
    DevPrint("\x03" + "[DEV] " + "\x04" + type + "\x03" + " killed, giving rewards:")
    foreach(pt in rewards)
        DevPrint("  " + "\x04" + pt + "\x01" + ": " + "\x05" + SessionState[pt] + "\x01" + " left.")
}

function OnWitchDeath(infected)
{
    SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5
    SessionState.PillSpawns = SessionState.PillSpawns + 1

    if(infected.GetModelName().find("bride") >= 0) // bride witch is more dangerous, give an extra reward
    {
        SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.25
        SessionState.PillSpawns = SessionState.PillSpawns + 0.5
        SessionState.PipeSpawns = SessionState.PipeSpawns + 0.5

        DevPrintRewards("Witch Bride", ["MedkitSpawns", "PillSpawns", "PipeSpawns"])
    } else {
        DevPrintRewards("Witch", ["PillSpawns", "PipeSpawns"])
    }

    SpawnWitchItems(infected)
}

function OnSpecialDeath(infected)
{
    SessionState.PillSpawns = SessionState.PillSpawns + 0.25
    SessionState.PipeSpawns = SessionState.PipeSpawns + 0.5

    DevPrintRewards("SI", ["PillSpawns", "PipeSpawns"])
}

function OnInfectedKilled(params)
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

function OnPlayerKilled(params)
{
    if ( !("userid" in params) )
        return;

    local victim = GetPlayerFromUserID( params["userid"] );

    if ( ( !victim ) || ( !victim.IsSurvivor() ) )
        return;

    local prevRagdoll = NetProps.GetPropEntity( victim, "m_hRagdoll" );
    if ( prevRagdoll != null )
        return;

    local clOrigin = victim.GetOrigin();

    local ragdoll = null;
    // cs_ragdoll can crash if proper netprops aren't set, some future-proofing
    // get rid of uninitialized ragdoll if something goes wrong here
    try
    {
        ragdoll = SpawnEntityFromTable( "cs_ragdoll", {} )
        NetProps.SetPropVector( ragdoll, "m_vecOrigin", clOrigin );
        NetProps.SetPropVector( ragdoll, "m_vecRagdollOrigin", clOrigin );
        NetProps.SetPropInt( ragdoll, "m_nModelIndex", NetProps.GetPropInt( victim, "m_nModelIndex" ) );
        NetProps.SetPropInt( ragdoll, "m_iTeamNum", NetProps.GetPropInt( victim, "m_iTeamNum" ) );
        NetProps.SetPropEntity( ragdoll, "m_hPlayer", victim );
        NetProps.SetPropInt( ragdoll, "m_iDeathPose", NetProps.GetPropInt( victim, "m_nSequence" ) );
        NetProps.SetPropInt( ragdoll, "m_iDeathFrame", NetProps.GetPropInt( victim, "m_flAnimTime" ) );
        NetProps.SetPropInt( ragdoll, "m_bClientSideAnimation", 1 );
        NetProps.SetPropInt( ragdoll, "m_iTeamNum", NetProps.GetPropInt( victim, "m_iTeamNum" ) );
        NetProps.SetPropInt( ragdoll, "m_nForceBone", NetProps.GetPropInt( victim, "m_nForceBone" ) );
        NetProps.SetPropInt( ragdoll, "m_ragdollType", 4 );
        NetProps.SetPropInt( ragdoll, "m_survivorCharacter", NetProps.GetPropInt( victim, "m_survivorCharacter" ) );
        NetProps.SetPropEntity( victim, "m_hRagdoll", ragdoll );

        //EntFire( "survivor_death_model", "Kill" );
        // EntFire is too slow and you can see one-frame image of death model
        for ( local body; body = Entities.FindByClassname( body, "survivor_death_model" ); )
        {
            body.Kill();
        }
    }
    catch (err)
    {
        if ( ragdoll != null && ragdoll.IsValid() )
            ragdoll.Kill();

        EntFire( "survivor_death_model", "BecomeRagdoll" );
    }
}

function OnGameEvent_player_death(params)
{
    OnInfectedKilled(params)
    OnPlayerKilled(params)
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

// function CollectWeaponInfo(invTable)
// {
//     local wep
//     local weapons = {
//         slot0 = null
//     }

//     if("slot0" in invTable) {
//         wep = invTable["slot0"]

//         weapons["slot0"] = {
//             type = wep.GetClassname(),
//             clip1 = wep.Clip1(),
//             clip2 = wep.Clip2(),
//             ammo = NetProps.GetPropInt(wep, "m_iExtraPrimaryAmmo")
//         }
//     }

//     return weapons
// }

// function CollectPlayerInfo(player) {
//     local invTable = {}
//     GetInvTable(player, invTable)

//     return {
//         model = player.GetModelName(),
//         weapons = CollectWeaponInfo(invTable),
//         health = {
//             perm = player.GetHealth(),
//             temp = player.GetHealthBuffer(),
//             revives = NetProps.GetPropInt(player, "m_currentReviveCount")
//         },
//     }
// }

// function SaveGameState()
// {
//     local player = null

//     // Iterate through every player
//     while(player = Entities.FindByClassname(player, "player"))
//     {
//         DumpObject(CollectPlayerInfo(player))
//         // printl("Player: " + player.GetPlayerName())

//         // printl("Modelname: " + player.GetModelName())

//         // // Add an empty table to store the inventory in
//         // local invTable = {}

//         // // Call the function to fill the table
//         // GetInvTable(player, invTable)

//         // // Check if the player has a primary weapon
//         // if("slot0" in invTable)
//         // {
//         //     printl("Primary weapon equipped: " + invTable.slot0)
//         // }
//         // else
//         // {
//         //     printl("Primary weapon not equipped!")
//         // }

//         // // Print all equipped weapons
//         // foreach(slot, weapon in invTable)
//         // {
//         //     printl("\t" + slot + "= " + weapon.GetClassname())
//         // }
//     }
// }

// function RestoreGameState()
// {

// }

function DevPrint(message) {
    if(!SessionState.DevMode)
        return;
    ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x01" + message);
}

function ToggleDevMode()
{
    SessionState.DevMode = !SessionState.DevMode
    ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + "[DEV] Dev mode turned: " + (SessionState.DevMode ? "\x05" + "ON" : "\x04" + "OFF"))
}

function DevPrintSessionState()
{
    DevPrint("\x03" + "[DEV] Initial state:")
    foreach(pt in ["MolotovSpawns", "Tier2Spawns", "MedkitSpawns", "PillSpawns", "PipeSpawns"])
        DevPrint("  " + "\x04" + pt + "\x01" + ": " + "\x05" + InitialState[pt] + "\x01" + " + " + "\x05" + GetExtraConsumableLimits(pt) + "\x01" + " extra.")

    foreach(sp in MobSpawns.tanks)
        DevPrint("  " + "\x04" + "Tank" + "\x01" + " at flow " + "\x05" + sp.flow + "%")
}

function OnGameEvent_player_say(params){

    local text,ent = null

    if("userid" in params && params.userid == 0){
        return
    }

    text = strip(params["text"].tolower())
    ent = GetPlayerFromUserID(params["userid"])

    if(text.len() < 1){
        return
    }

    local steamID = ent.GetNetworkIDString()

    switch(text){
        case "!dev":
            ToggleDevMode()
            break;
        // case "!save":
        //     SaveGameState();
        //     break;
        // case "!restore":
        //     RestoreGameState();
        //     break;
    }
}

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

    local maxHealth = health // we want special tank to burn in half the time

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
        DevPrint("\x03" + "[DEV] Spawned " + "\x04" + "Mini-tank" + "\x03" + " with " + "\x04" + health + "\x03" + " HP.")
    } else {
        DevPrint("\x03" + "[DEV] Spawned " + "\x04" + "Tank" + "\x03" + " with " + "\x04" + health + "\x03" + " HP.")
    }

    tank.SetMaxHealth(maxHealth)
    tank.SetHealth(health)

    if(SessionState.IsFinale && Time() > SessionState.TankSpawnDelay) {
        SessionState.NextTankIsSpecial = true
        SessionState.TankSpawnDelay = Time() + 25 // prevent filling server with tanks, number higher for swamp fever
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
    DirectorOptions.cm_AggressiveSpecials = true;
    ZSpawn( { type = 8 } );
    DirectorOptions.cm_AggressiveSpecials = false;

    StartAssault();
    DevPrint("\x03" + "[DEV] Car alarm triggered, spawning " + "\x04" + "Tank" + "\x03" + ".")
}

ValidSpawns <-
{
    MolotovSpawns = [],
    PipeSpawns = [],
    PillSpawns = [],
    MedkitSpawns = []
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
    DevPrint("\x03 [DEV] Spawning reward " + "\x04" + classname + "\x03" + " at flow " + "\x04" + floor((spawnpoint.flow / GetMaxFlowDistance()) * 1000) / 10 + "\x03" + "%.")

    return true
}

MobSpawns <-
{
    tanks = []
}

function FillTankSpawns()
{
    local spBase = 25, spRange = 10
    local tankSpawns = 2

    if(RandomInt(1, 3) > 3)
        tankSpawns = 3  # chance for three tanks

    if(Director.IsFirstMapInScenario()) {
        tankSpawns = tankSpawns - 1 # less tanks in first map
        spBase = 50
        spRange = 35
    }

    for (local i = 0; i < tankSpawns; i = i + 1)
        MobSpawns.tanks.append({ flow = spBase * (i + 1) + RandomInt(-spRange, spRange), used = false })
}

function ExponentialInterpolate(a, b, x, min_x, max_x) {
    // Clamp x to be within the range [min_x, max_x]
    if (x < min_x) x = min_x;
    if (x > max_x) x = max_x;

    // Normalize x to a value between 0 and 1
    local t = (x - min_x) / (max_x - min_x);

    // Apply an exponential easing to t
    local factor = 2; // This controls the steepness of the ramp (2 is a common choice)
    local eased_t = pow(t, factor);

    // Interpolate between a and b based on eased_t
    return a + (b - a) * eased_t;
}

function TickTankSupport()
{
    if(Director.IsTankInPlay())
    {
        if(!SessionState.FlowTank.isSpawned) {
            DirectorOptions.CommonLimit = 20
            DirectorOptions.MobMinSize = 10
            DirectorOptions.MobMaxSize = 20
        } else {
            local maxSurvivor = Director.GetHighestFlowSurvivor()

            local flow = (GetFlowDistanceForPosition(maxSurvivor ? maxSurvivor.GetOrigin() : Director.GetFurthestSurvivorFlow()) / GetMaxFlowDistance()) * 100

            if(!SessionState.FlowTank.inPlay) {
                SessionState.FlowTank.flowMin = Min(flow + 5, 90) // start ramping up at +5% extra flow
                SessionState.FlowTank.flowMax = Min(flow + 20, 110)
                SessionState.FlowTank.inPlay = true
                SessionState.FlowTank.playedMegaMobSound = false
                DevPrint("\x03" + "[DEV] " + "\x04" + "Tank" + "\x03" + " in play, reducing commons.")
            }

            local infected = ExponentialInterpolate(5, 50, flow, SessionState.FlowTank.flowMin, SessionState.FlowTank.flowMax)

            if(infected >= 50 && !SessionState.FlowTank.playedMegaMobSound) {
                SessionState.FlowTank.playedMegaMobSound = true
                // Director.PlayMegaMobWarningSounds()
                EntFire( "info_director", "ForcePanicEvent" );
                DevPrint("\x03" + "[DEV] Players rushing " + "\x04" + "Tank" + "\x03" + " releasing a horde.")
            }


            DirectorOptions.CommonLimit = ceil(infected)
            DirectorOptions.MobMinSize = ceil(infected * 0.5)
            DirectorOptions.MobMaxSize = ceil(infected)

            if(SessionState.DevMode)
            {
                SessionState.DevTicks = SessionState.DevTicks - 1
                if(SessionState.DevTicks <= 0)
                {
                    if(SessionState.FlowTank.inPlay)
                    DevPrint("\x03" + "[DEV] " + "\x04" + "Tank" + "\x03" + " in play, limiting to " + "\x04" + floor(infected * 10) / 10 + "\x03" + " commons.")
                    SessionState.DevTicks = 3
                }
            }
        }
    }
    else
    {
        DirectorOptions.CommonLimit = 50
        DirectorOptions.MobMinSize = 25
        DirectorOptions.MobMaxSize = 50
    }
}

function TickTankFlow()
{
    if(SessionState.IsFinale) // no extra tanks during finale
        return

    local flow = (Director.GetFurthestSurvivorFlow() / GetMaxFlowDistance()) * 100

    foreach(sp in MobSpawns.tanks)
    {
        if(sp.used || sp.flow > flow) continue

        ZSpawn({ type = 8 })
        sp.used = true

        if(!SessionState.FlowTank.isSpawned) {
            SessionState.FlowTank.inPlay = Director.IsTankInPlay()
            SessionState.FlowTank.isSpawned = true
        }
    }
}

function DevTickSaferoomPrint()
{
    if(SessionState.DevSaferoomExit || !Director.HasAnySurvivorLeftSafeArea())
        return

    SessionState.DevSaferoomExit = true
    DevPrintSessionState()
}

function Update()
{
    TickTankSupport()
    TickTankFlow()
    DevTickSaferoomPrint()
}

function SortSpawns(a, b)
{
    return a.flow - b.flow;
}

function CollectSpawns(classnames, spawnKey)
{
    local ent

    foreach(classname in classnames)
        while (ent = Entities.FindByClassname(ent, classname)) {
            AddSpawn(ValidSpawns[spawnKey], ent)
            ent.Kill()
        }

    ValidSpawns[spawnKey].sort(SortSpawns)

    return ValidSpawns[spawnKey]
}


function LimitMedkitSpawnPoint()
{
    local classnames = ["weapon_first_aid_kit", "weapon_first_aid_kit_spawn", "weapon_defibrillator", "weapon_defibrillator_spawn"]
    local spawnKey = "MedkitSpawns"

    local maxFlowDist = GetMaxFlowDistance()
    local minFlow = Director.IsFirstMapInScenario() ? 0 : (Director.GetFurthestSurvivorFlow() / maxFlowDist) * 100 + 5 // first map can spawn medkits at saferoom, other maps can't
    local spawns = CollectSpawns(classnames, spawnKey).filter(function(i, spawn) { return (spawn.flow / maxFlowDist) * 100 >= minFlow })
    local count = SessionState[spawnKey] <= spawns.len() ? SessionState[spawnKey] : spawns.len()

    SessionState[spawnKey] = SessionState[spawnKey] - count

    for(local i = 0; i < count; i++) {
        local spawned = false

        do {
            local spawn = spawns[RandomInt(0, spawns.len() - 1)]
            local flow = spawn.flow / maxFlowDist

            if(spawn.used)
                continue

            SpawnEntityFromTable("weapon_first_aid_kit", spawn.spawnTable)

            spawn.used = true
            spawned = true
        } while(!spawned)
    }
}

function LimitSpawnPoint(classnames, spawnKey)
{
    local classname
    switch(spawnKey) {
        case "MolotovSpawns": classname = "weapon_molotov"; break;
        case "PipeSpawns":  classname = "weapon_pipe_bomb"; break;
        case "MedkitSpawns": classname = "weapon_first_aid_kit"; break;
        case "PillSpawns": classname = "weapon_pain_pills"; break;
        default:
            Msg("[ATTRITION] Error cannot spawn " + spawnKey + "\n")
            return
    }

    local spawns = CollectSpawns(classnames, spawnKey)
    local count = SessionState[spawnKey] <= spawns.len() ? SessionState[spawnKey] : spawns.len()

    SessionState[spawnKey] = SessionState[spawnKey] - count

    for(local i = 0; i < count; i++) {
        local spawned = false

        do {
            local spawn = spawns[RandomInt(0, spawns.len() - 1)]

            if(spawn.used)
                continue

            SpawnEntityFromTable(classname, spawn.spawnTable)

            spawn.used = true
            spawned = true
        } while(!spawned)
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

    foreach(classname in WeaponsTier2)
    {
        while (ent = Entities.FindByClassname(ent, classname + "*"))
        {
            if (SessionState.Tier2Spawns < 1) {
                ent.Kill()
                continue
            }

            SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1
        }
    }
}

SavedState <- {
    DevMode = 0,
    MolotovSpawns = 0,
    MedkitSpawns = 0,
    PillSpawns = 0,
    PipeSpawns = 0,
}

function Max(a, b) { return a > b ? a : b; }
function Min(a, b) { return a < b ? a : b; }

function GetExtraConsumableLimits(savedKey)
{
    local count = 0

    switch(savedKey)
    {
        case "MolotovSpawns": count = Min(SavedState[savedKey], 0.5); break;
        case "MedkitSpawns": count = Min(SavedState[savedKey], 1); break;
        case "PillSpawns": count = Min(SavedState[savedKey], 1.5); break;
        case "PipeSpawns": count = Min(SavedState[savedKey], 2); break;
    }

    return count
}

function RestoreConsumables()
{
    RestoreTable("savedState", SavedState)
    SessionState.DevMode = SavedState.DevMode

    foreach(sp in ["MolotovSpawns", "MedkitSpawns", "PillSpawns", "PipeSpawns"]) {
        local extra = GetExtraConsumableLimits(sp)
        Msg("[ATTRITION] Starting map with " + sp + " " + SessionState[sp] + " + " + extra + "\n")
        SessionState[sp] = SessionState[sp] + extra
    }

    SessionState.DevMode = SavedState.DevMode
}

function OnGameEvent_round_start_post_nav(params) {
    RestoreConsumables()
    FillTankSpawns()

    LimitSpawnPoint(["weapon_molotov", "weapon_molotov_spawn"], "MolotovSpawns")
    LimitSpawnPoint(["weapon_pipe_bomb", "weapon_pipe_bomb_spawn", "weapon_vomitjar", "weapon_vomitjar_spawn"], "PipeSpawns")
    LimitMedkitSpawnPoint()
    LimitSpawnPoint(["weapon_pain_pills", "weapon_pain_pills_spawn", "weapon_adrenaline", "weapon_adrenaline_spawn"], "PillSpawns")

    ModifyWeaponSpawns()
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

    cm_ShouldHurry = true
    cm_AggressiveSpecials = false

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
        if (classname in weaponsToConvert)
            return weaponsToConvert[classname];

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
