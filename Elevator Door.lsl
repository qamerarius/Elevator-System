// ===== Tube-Rotate Door (Linked Child; NO KFM) =====
integer CHANNEL = -987654;
string  ELEVATOR_ID = "CAR_A";

integer CHILD_LINK    = LINK_THIS;
vector  AXIS_LOCAL    = <0.0, 0.0, 1.0>;
float   OPEN_ANGLE_DEG   = 0.0;
float   CLOSED_ANGLE_DEG = 90.0;

float   STEP_TIME     = 1.0;
integer STEP_COUNT    = 20;

string  SND_CLOSE = "";
string  SND_OPEN  = "";

integer gListen;
integer gIsClosed = FALSE;
integer gIsMoving = FALSE;
rotation gBaseLocalRot;

float deg2rad(float d){ return d * PI / 180.0; }
rotation axisAngleLocal(vector axis_local, float degrees){
    vector a = llVecNorm(axis_local);
    return llAxisAngle2Rot(a, deg2rad(degrees));
}

integer snapOpen(){
    gBaseLocalRot = llList2Rot(llGetLinkPrimitiveParams(CHILD_LINK, [PRIM_ROT_LOCAL]), 0);
    llSetLinkPrimitiveParamsFast(CHILD_LINK, [PRIM_ROT_LOCAL, gBaseLocalRot * axisAngleLocal(AXIS_LOCAL, OPEN_ANGLE_DEG)]);
    gIsClosed = FALSE;
    return 0;
}

integer closeDoors(){
    if (gIsMoving || gIsClosed) return 0;
    gIsMoving = TRUE; if (SND_CLOSE != "") llPlaySound(SND_CLOSE, 1.0);
    float dt = STEP_TIME / (float)STEP_COUNT;
    integer i;
    for (i = 1; i <= STEP_COUNT; ++i){
        float t = (float)i / (float)STEP_COUNT;
        float ang = OPEN_ANGLE_DEG + (CLOSED_ANGLE_DEG - OPEN_ANGLE_DEG) * t;
        llSetLinkPrimitiveParamsFast(CHILD_LINK, [PRIM_ROT_LOCAL, gBaseLocalRot * axisAngleLocal(AXIS_LOCAL, ang)]);
        llSleep(dt);
    }
    gIsClosed = TRUE; gIsMoving = FALSE;
    llRegionSay(CHANNEL, "DOORS_CLOSED|" + ELEVATOR_ID);
    return 0;
}

integer openDoors(){
    if (gIsMoving || !gIsClosed) return 0;
    gIsMoving = TRUE; if (SND_OPEN != "") llPlaySound(SND_OPEN, 1.0);
    float dt = STEP_TIME / (float)STEP_COUNT;
    integer i;
    for (i = STEP_COUNT - 1; i >= 0; --i){
        float t = (float)i / (float)STEP_COUNT;
        float ang = OPEN_ANGLE_DEG + (CLOSED_ANGLE_DEG - OPEN_ANGLE_DEG) * t;
        llSetLinkPrimitiveParamsFast(CHILD_LINK, [PRIM_ROT_LOCAL, gBaseLocalRot * axisAngleLocal(AXIS_LOCAL, ang)]);
        llSleep(dt);
    }
    gIsClosed = FALSE; gIsMoving = FALSE;
    return 0;
}

default{
    state_entry(){ gListen = llListen(CHANNEL, "", NULL_KEY, ""); snapOpen(); }
    on_rez(integer p){ llResetScript(); }
    listen(integer ch, string name, key id, string msg){
        if (ch != CHANNEL) return;
        list L = llParseString2List(msg, ["|"], []);
        if (llGetListLength(L) < 2) return;
        if (llList2String(L,1) != ELEVATOR_ID) return;
        string cmd = llList2String(L,0);
        if (cmd == "CLOSE") closeDoors();
        else if (cmd == "OPEN") openDoors();
    }
}
