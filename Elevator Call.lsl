// ===== Hall Call Button (standalone per landing) =====
integer CHANNEL = -987654;
string  ELEVATOR_ID = "CAR_A";
integer FLOOR_INDEX = 0; // this landing's floor index (0..4)

float COOLDOWN = 0.6;
float lastClick = -99.0;

default
{
    touch_start(integer n){
        float now = llGetTime();
        if (now - lastClick < COOLDOWN) return;
        lastClick = now;

        llRegionSay(CHANNEL, "HALL_CALL|" + ELEVATOR_ID + "|" + (string)FLOOR_INDEX);
        // Optional: llPlaySound("your-sound-uuid", 1.0);
    }
}
