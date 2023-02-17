

$regfile = "m8def.dat"
$crystal = 16000000
$baud = 250000

$include "ev1527_decoder.bas"

Status_light Alias Portc.0 : Ddrc.0 = 1
Relay_light Alias Portd.7 : Ddrd.7 = 1

Key_learn Alias Pinc.4 : Ddrc.4 = 0
Key_activation Alias Pinc.5 : Ddrc.5 = 0


Waitms 100

Enable Interrupts
Gosub _ev1527d_start_detect_mode

Do
Loop

_ev1527d_detected:

   Toggle Status_light
   Printbin _ev1527d_code(1) ; 3

Return

_ev1527d_safe_detected:
Return

_ev1527d_match_detected:
Return