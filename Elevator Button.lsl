// ===== Inside Cab Floor Button (child prim) =====
integer CHANNEL = -987654;
string  ELEVATOR_ID = "CAR_A";
integer FLOOR_INDEX = 2; // set per button (0..4)

float COOLDOWN = 0.4;
float lastClick = -99.0;

default
{
    touch_start(integer n){
        float now = llGetTime();
        if (now - lastClick < COOLDOWN) return;
        lastClick = now;

        //llRegionSay(CHANNEL, "CALL_FLOOR|" + ELEVATOR_ID + "|" + (string)FLOOR_INDEX);
        llMessageLinked(LINK_SET,CHANNEL, "CALL_FLOOR|" + ELEVATOR_ID + "|" + (string)FLOOR_INDEX,"");
        // Optional: llPlaySound("your-sound-uuid", 1.0);
    }
}
