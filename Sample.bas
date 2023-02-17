

$regfile = "m8def.dat"
$crystal = 16000000
$baud = 250000

$include "ev1527_decoder.bas"

Detect_light Alias Portc.1 : Ddrc.1 = 1
Status_light Alias Portc.0 : Ddrc.0 = 1
Relay_light Alias Portd.7 : Ddrd.7 = 1

Key_learn Alias Pinc.4 : Ddrc.4 = 0
Key_activation Alias Pinc.5 : Ddrc.5 = 0

Waitms 100

Enable Interrupts
Gosub _ev1527d_start_detect_mode

Do

   If _ev1527d_status = _ev1527d_status_safe_mode Then

      Toggle Status_light : Waitms 50

   Elseif _ev1527d_status = _ev1527d_status_detect_mode Then

      Toggle Status_light : Waitms 100
      Toggle Status_light : Waitms 50

   Elseif _ev1527d_status = _ev1527d_status_match_mode Then

      Set Status_light

   Elseif _ev1527d_status = _ev1527d_status_stop Then

      Reset Status_light

   End If

   '----------------------------------------------------------------------------

   If Key_learn = 0 Then

      Do : Waitms 25 : Loop Until Key_learn = 1

      If _ev1527d_status <> _ev1527d_status_stop Then
         If _ev1527d_status = _ev1527d_status_match_mode Then
            Gosub _ev1527d_start_safe_mode
         Else
            Gosub _ev1527d_start_match_mode
         End If
      End If

   End If

   If Key_activation = 0 Then

      Do : Waitms 25 : Loop Until Key_activation = 1

      If _ev1527d_status <> _ev1527d_status_stop Then

         Gosub _ev1527d_stop

      Else

         Gosub _ev1527d_start_match_mode

      End If

   End If

Loop

End

_ev1527d_detected:

   Toggle Detect_light
   Printbin _ev1527d_code(1) ; 3

Return

_ev1527d_safe_detected:

   Gosub _ev1527d_stop

   Print "Safe:";
   Print Hex(_ev1527d_code(1)) ; Hex(_ev1527d_code(2)) ; Hex(_ev1527d_code(3))
   Dim Dummy As Byte
   Dummy = Memcopy(_ev1527d_code(1) , _ev1527d_target_code(1) , 3)

   Gosub _ev1527d_start_match_mode

Return

_ev1527d_match_detected:


   Toggle Relay_light

   Print "Match:";
   Print Hex(_ev1527d_code(1)) ; Hex(_ev1527d_code(2)) ; Hex(_ev1527d_code(3))

Return