// ===== Elevator Car (Root Prim) — Robust KFM (triple frames + local delta) =====
integer CHANNEL = -987654;
string  ELEVATOR_ID = "CAR_A";

// Absolute ROOT-Z targets (from Edit)
list FLOOR_ROOT_ZS = [22.03, 27.75];

// Motion & timing
float TRAVEL_SPEED   = 3.0;   // m/s
float ARRIVE_DWELL   = 0.15;  // s after KFM duration
float DOOR_TIMEOUT   = 10.0;  // s to wait for DOORS_CLOSED

// Tolerances
float SAME_FLOOR_EPS = 0.08;  // "already here"
float SAFE_MIN_Z     = 0.10;
float SAFE_MAX_Z     = 4090.0;

// Debug
integer DEBUG = TRUE;

// Internals
integer vDestination;
integer vCurrentFloor;
integer gListen;
integer gMoving = FALSE;
integer gAwaitingDoors = FALSE;
float   gTargetRootZ = 0.0;
integer gTargetIndex = -1;
float   gMoveTime = 0.13333;
float   gCloseDeadline = 0.0;

vector posAtRootZ(float rootZ){ vector p = llGetPos(); return <p.x, p.y, rootZ>; }
float  distZ(float a, float b){ return llFabs(a - b); }

float computeDuration(float startZ, float endZ){
    float d = distZ(startZ, endZ);
    if (TRAVEL_SPEED <= 0.0) TRAVEL_SPEED = 2.5;
    float t = d / TRAVEL_SPEED; if (t < 0.05) t = 0.05; return t;
}

integer isAtRootZ(float targetRootZ){
    vector here = llGetPos();
    if (llFabs(here.z - targetRootZ) <= SAME_FLOOR_EPS) return TRUE;
    return FALSE;
}

integer requestDoorsClose(){
    if (DEBUG) llOwnerSay("TX: CLOSE|" + ELEVATOR_ID);
    llMessageLinked(LINK_SET,CHANNEL, "CLOSE|" + ELEVATOR_ID,"");
    llRegionSay(CHANNEL, "CLOSE|" + ELEVATOR_ID + "|"+ (string)vCurrentFloor);
    gCloseDeadline = llGetUnixTime() + (integer)DOOR_TIMEOUT;
    gAwaitingDoors = TRUE;
    return 0;
}

integer beginMoveKFM(float targetRootZ){
    // Clamp target
    if (targetRootZ < SAFE_MIN_Z) targetRootZ = SAFE_MIN_Z;
    if (targetRootZ > SAFE_MAX_Z) targetRootZ = SAFE_MAX_Z;

    // Fully stop any prior KFM and ensure non-physical
    llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
    llSetStatus(STATUS_PHYSICS, FALSE);

    // Compute world -> local delta
    vector hereW  = llGetPos();
    vector thereW = posAtRootZ(targetRootZ);
    vector deltaW = hereW - thereW;
    rotation r    = llGetRot();
    vector deltaL = deltaW / r; // local-space translation required

    gMoveTime = computeDuration(hereW.z, targetRootZ);

    // PRIME: tiny no-op triple so the sim is definitely in (translation|rotation) mode
    llSetKeyframedMotion([ <0,0,0>, ZERO_ROTATION, gMoveTime ],[ KFM_MODE, (KFM_TRANSLATION | KFM_ROTATION) ]);

    // Real move: triple frame [local translation, ZERO_ROTATION, time]
    llSetKeyframedMotion([ deltaL, ZERO_ROTATION, gMoveTime ],[ KFM_MODE, (KFM_TRANSLATION | KFM_ROTATION) ]);

    gMoving = TRUE;
    llSetTimerEvent(gMoveTime + ARRIVE_DWELL);

    if (DEBUG){
        float z0 = (float)(llRound(hereW.z * 100.0) / 100.0);
        float z1 = (float)(llRound(targetRootZ * 100.0) / 100.0);
        float dz = (float)(llRound(deltaW.z * 100.0) / 100.0);
        llOwnerSay("KFM: z " + (string)z0 + " → " + (string)z1 + " (Δz=" + (string)dz + "m) t=" + (string)gMoveTime + "s");
    }
    return 0;
}

integer sendArrived(){ if (DEBUG) llOwnerSay("TX: ARRIVED|" + ELEVATOR_ID); llRegionSay(CHANNEL, "ARRIVED|" + ELEVATOR_ID); return 0; }

default{
    state_entry(){
        llSetKeyframedMotion([], [KFM_COMMAND, KFM_CMD_STOP]);
        llSetStatus(STATUS_PHYSICS, FALSE);
        gListen = llListen(CHANNEL, "", NULL_KEY, "");
        if (DEBUG) llOwnerSay("Elevator ready. Floors=" + (string)llGetListLength(FLOOR_ROOT_ZS));
    }

    on_rez(integer p){ llResetScript(); }
    changed(integer c){ if (c & CHANGED_OWNER) llResetScript(); }

    listen(integer ch, string name, key id, string msg){
        if (ch != CHANNEL) return;
        if (DEBUG) llOwnerSay("RX: " + msg);

        list L = llParseString2List(msg, ["|"], []);
        integer n = llGetListLength(L); if (n < 2) return;

        string cmd = llList2String(L,0);
        string eid = llList2String(L,1);
        if (eid != ELEVATOR_ID) return;

        if ((cmd == "CALL_FLOOR" || cmd == "HALL_CALL") && n >= 3){
            if (gMoving || gAwaitingDoors) return;
            integer idx = (integer)llList2String(L,2);
            vDestination = idx;
            if (idx < 0 || idx >= llGetListLength(FLOOR_ROOT_ZS)) return;

            float targetRootZ = (float)llList2String(FLOOR_ROOT_ZS, idx);
            if (isAtRootZ(targetRootZ)) return;

            gTargetIndex = idx; gTargetRootZ = targetRootZ;
            requestDoorsClose();
            return;
        }

        if (cmd == "DOORS_CLOSED"){
            if (!gAwaitingDoors) return;
            gAwaitingDoors = FALSE;
            beginMoveKFM(gTargetRootZ);
            return;
        }
    }
    link_message( integer ch, integer num, string msg, key id ){
        if (DEBUG) llOwnerSay("RX: " + msg);

        list L = llParseString2List(msg, ["|"], []);
        integer n = llGetListLength(L); if (n < 2) return;

        string cmd = llList2String(L,0);
        string eid = llList2String(L,1);
        if (eid != ELEVATOR_ID) return;

        if ((cmd == "CALL_FLOOR" || cmd == "HALL_CALL") && n >= 3){
            if (gMoving || gAwaitingDoors) return;
            integer idx = (integer)llList2String(L,2);

            if (idx < 0 || idx >= llGetListLength(FLOOR_ROOT_ZS)) return;

            float targetRootZ = (float)llList2String(FLOOR_ROOT_ZS, idx);
            if (isAtRootZ(targetRootZ)) return;
            vDestination = idx;
            gTargetIndex = idx; gTargetRootZ = targetRootZ;
            requestDoorsClose();
            return;
        }

        if (cmd == "DOORS_CLOSED"){
            if (!gAwaitingDoors) return;
            gAwaitingDoors = FALSE;
            beginMoveKFM(gTargetRootZ);
            return;
        }
    }

    timer(){
        if (gMoving){
            gMoving = FALSE;
            llSetTimerEvent(0.0);
            sendArrived();
            if (DEBUG) llOwnerSay("TX Channel: "+ (string)CHANNEL+ " Cmd: OPEN|" + ELEVATOR_ID);
            llMessageLinked(LINK_SET,CHANNEL, "OPEN|" + ELEVATOR_ID,"");
            llRegionSay(CHANNEL, "OPEN|" + ELEVATOR_ID + "|"+ (string)vDestination);
            vCurrentFloor = vDestination;
            return;
        }

        if (gAwaitingDoors && llGetUnixTime() > gCloseDeadline){
            gAwaitingDoors = FALSE;
            llOwnerSay("Door close timeout—aborting move.");
            llSetTimerEvent(0.0);
        } else {
            llSetTimerEvent(0.0);
        }
    }
}
