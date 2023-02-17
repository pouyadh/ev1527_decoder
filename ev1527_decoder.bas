
   jmp _ev1527d_end

   'Min/Max of RoSc&TD table on EV1527 datasheet(in micro-secound)
   Const _ev1527d_td_min_us = 1200
   Const _ev1527d_td_max_us = 3200

   'Timing Strictness (1-3)
   '1 -> Checks TPreamble and TData
   '2 -> Also checks TPreamble_High and TData_High
   '3 -> Also checks TPreamble total to high Ratio
   'Default: 1
   Const _ev1527d_timing_strictness = 1

   'When (Timing Strictness = 3)
   'Min/Max of TPreamble total to high Ratio
   Const _ev1527d_tp2tph_rate_min = 20
   Const _ev1527d_tp2tph_rate_max = 40

   'Number of codes to be received as verification in "Safe Mode"
   'Default: 2
   Const _ev1527d_safe_mode_verify_count = 2

   'Number of codes to be received as verification in "Match Mode"
   'Default: 1
   Const _ev1527d_match_mode_verify_count = 1

   'After recognizing the code , You need to release the key
   'And wait for the release delay to end (in mili-secound)
   'When _ev1527d_release_delay_ms is equal to 0, Timer2 is free to use for other purposes
   'When _ev1527d_release_delay_ms is more than 0, Timer2 will be used and can't be used for anything else
   'Default: 1000
   Const _ev1527d_release_delay_ms = 500



   '** Auto calculation
   '** DO NOT CHANGE THEM

   'Timer1 calculation
   Const _ev1527d_tp_max_s = _ev1527d_td_max_us * 8 / 10 ^ 6
   Const _ev1527d_timer1_prescale_min = _ev1527d_tp_max_s * 2 * _xtal / 65536
   Const _ev1527d_timer1_prescale = 8 ^ Fix(log(_ev1527d_timer1_prescale_min) / Log(8) + 1)
   Const _ev1527d_timer1_frequency = _xtal / _ev1527d_timer1_prescale
   Const _ev1527d_timer1_cycles_per_us = _ev1527d_timer1_frequency / 10 ^ 6
   Const _ev1527d_timer1_cycles_per_ms = _ev1527d_timer1_frequency / 10 ^ 3

   #if _ev1527d_release_delay_ms > 0

      'Timer2 calculation
      Const _ev1527d_timer2_prescale_min = 1 / 10 ^ 3 * _xtal / 256
      Const _ev1527d_timer2_prescale = 8 ^ Fix(log(_ev1527d_timer2_prescale_min) / Log(8) + 1)
      Const _ev1527d_timer2_frequency = _xtal / _ev1527d_timer2_prescale
      Const _ev1527d_timer2_cycles_per_us = _ev1527d_timer2_frequency / 10 ^ 6
      Const _ev1527d_timer2_cycles_per_ms = _ev1527d_timer2_frequency / 10 ^ 3

   #endif


   'Min/Max of 1 unit of data cycle
   Const _ev1527d_tunit_min = _ev1527d_td_min_us * _ev1527d_timer1_cycles_per_us \ 4
   Const _ev1527d_tunit_max = _ev1527d_td_max_us * _ev1527d_timer1_cycles_per_us \ 4

   'Min/Max of data cycle (in Timer1-Cycle)
   Const _ev1527d_td_min = _ev1527d_tunit_min * 4
   Const _ev1527d_td_max = _ev1527d_tunit_max * 4
   'Min/Max of data "0" cycle timings
   Const _ev1527d_t0h_min = _ev1527d_tunit_min
   Const _ev1527d_t0h_max = _ev1527d_tunit_max
   Const _ev1527d_t0l_min = _ev1527d_tunit_min * 3
   Const _ev1527d_t0l_max = _ev1527d_tunit_max * 3
   'Min/Max of data "1" cycle timings
   Const _ev1527d_t1h_min = _ev1527d_tunit_min * 3
   Const _ev1527d_t1h_max = _ev1527d_tunit_max * 3
   Const _ev1527d_t1l_min = _ev1527d_tunit_min
   Const _ev1527d_t1l_max = _ev1527d_tunit_max
   'Min/Max of preamble cycle timings
   Const _ev1527d_tp_min = _ev1527d_tunit_min * 32
   Const _ev1527d_tp_max = _ev1527d_tunit_max * 32
   Const _ev1527d_tph_min = _ev1527d_tunit_min
   Const _ev1527d_tph_max = _ev1527d_tunit_max
   Const _ev1527d_tpl_min = _ev1527d_tunit_min * 31
   Const _ev1527d_tpl_max = _ev1527d_tunit_max * 31


   Dim _ev1527d_code(3) As Byte , _ev1527d_target_code(3) As Byte
   Dim _ev1527d_buffer(3) As Byte , _ev1527d_previous_code(3) As Byte
   Dim _ev1527d_dummy_byte(2) As Byte
   Dim _ev1527d_safe_verify_counter As Byte , _ev1527d_match_verify_counter As Byte
   Dim _ev1527d_ivalidation As Byte , _ev1527d_ibit As Byte , _ev1527d_ibyte As Byte
   Dim _ev1527d_th As Word , _ev1527d_tl As Word , _ev1527d_thl As Word
   Dim _ev1527d_t_range(2) As Word , _ev1527d_th_ref As Word
   Dim _ev1527d_no_previous_match_ms As Word
   Dim _ev1527d_no_target_match_ms As Word
   Dim _ev1527d_status As Byte
   Const _ev1527d_status_stop = 0
   Const _ev1527d_status_detect_mode = 1
   Const _ev1527d_status_safe_mode = 2
   Const _ev1527d_status_match_mode = 3


   On Capture1 _ev1527d_capture1i

   #if _ev1527d_release_delay_ms > 0

      On Compare2 _ev1527d_ocr2i

   #endif


_ev1527d_start_detect_mode:

      Gosub _ev1527d_start
      _ev1527d_status = _ev1527d_status_detect_mode

Return

_ev1527d_start_safe_mode:


   Gosub _ev1527d_start
   _ev1527d_status = _ev1527d_status_safe_mode

Return
_ev1527d_start_match_mode:

   Gosub _ev1527d_start
   _ev1527d_status = _ev1527d_status_match_mode

Return


_ev1527d_start:

   Gosub _ev1527d_stop

   Config Timer1 = Timer , Prescale = _ev1527d_timer1_prescale

   Start Timer1
   Enable Capture1
   Set Tccr1b.icnc1                                         '<-- Noise Canceler = on
   Set Tccr1b.ices1                                         '<-- Select rising edge

   #if _ev1527d_release_delay_ms > 0

      Config Timer2 = Timer , Prescale = _ev1527d_timer2_prescale
      Tccr2.3 = 1                                       'CTC
      Ocr2 = _ev1527d_timer2_cycles_per_ms
      Start Timer2
      Enable Compare2

   #endif

Return


_ev1527d_stop:

   Stop Timer1 : Tcnt1 = 0
   Disable Timer1 : Set Tifr.tov1
   Disable Capture1 : Set Tifr.icf1
   _ev1527d_buffer(1) = 0 : _ev1527d_buffer(2) = 0 : _ev1527d_buffer(3) = 0
   _ev1527d_safe_verify_counter = 0 : _ev1527d_match_verify_counter = 0
   _ev1527d_ivalidation = 0

   #if _ev1527d_release_delay_ms > 0

      Stop Timer2 : Tcnt2 = 0
      Disable Compare2 : Set Tifr.ocf2
      _ev1527d_no_previous_match_ms = 0
      _ev1527d_no_target_match_ms = 0

   #endif

   _ev1527d_status = _ev1527d_status_stop

Return


#if _ev1527d_release_delay_ms > 0

   _ev1527d_ocr2i:

      If _ev1527d_no_previous_match_ms <> &HFFFF _
      Then Incr _ev1527d_no_previous_match_ms

      If _ev1527d_no_target_match_ms <> &HFFFF _
      Then Incr _ev1527d_no_target_match_ms

   Return

#endif


_ev1527d_capture1i:

   sbic tccr1b , ices1
   rjmp _ev1527d_Capture1i_1

   _ev1527d_capture1i_0:

      Set Tccr1b.ices1
      _ev1527d_th = Icr1
      rjmp _ev1527d_capture1i_exit


   _ev1527d_capture1i_1:

      Tcnt1 = 0
      Reset Tccr1b.ices1
      _ev1527d_thl = Icr1


      If _ev1527d_ivalidation = 0 Then

         If _ev1527d_thl < _ev1527d_tp_min Or _
            _ev1527d_thl > _ev1527d_tp_max Then Jmp _ev1527d_capture1i_invalid

         #if _ev1527d_timing_strictness > 1

            If _ev1527d_th < _ev1527d_tph_min Or _
               _ev1527d_th > _ev1527d_tph_max Then Jmp _ev1527d_capture1i_invalid

         #endif

         #if _ev1527d_timing_strictness > 2

            _ev1527d_t_range(1) = Th * 20
            _ev1527d_t_range(2) = Th * 40

            If _ev1527d_thl < _ev1527d_t_range(1) Or _
               _ev1527d_thl > _ev1527d_t_range(2) Then Jmp _ev1527d_capture1i_invalid

         #endif

         Gosub _ev1527d_preamble_detected
         'Set Ot

      Elseif _ev1527d_ivalidation = 1 Then

         If _ev1527d_thl < _ev1527d_td_min Or _
            _ev1527d_thl > _ev1527d_td_max Then Rjmp _ev1527d_capture1i_invalid

         Shift _ev1527d_buffer(_ev1527d_ibyte) , Left

         _ev1527d_tl = _ev1527d_thl - _ev1527d_th

         If _ev1527d_th > _ev1527d_tl Then

            _ev1527d_t_range(1) = _ev1527d_th_ref * 5
            _ev1527d_t_range(2) = _ev1527d_th_ref * 7

            Incr _ev1527d_buffer(_ev1527d_ibyte)
         Else

            _ev1527d_t_range(1) = _ev1527d_th_ref
            _ev1527d_t_range(2) = _ev1527d_th_ref * 3

         End If

         #if _ev1527d_timing_strictness > 1

            If _ev1527d_th < _ev1527d_t_range(1) Or _
               _ev1527d_th > _ev1527d_t_range(2) Then Jmp _ev1527d_capture1i_invalid

         #endif

         Incr _ev1527d_ibit

         If _ev1527d_ibit = 8 Then
            _ev1527d_ibit = 0
            Incr _ev1527d_ibyte
         End If

         If _ev1527d_ibyte = 4 Then _ev1527d_ivalidation = 2

      Elseif _ev1527d_ivalidation = 2 Then

         If _ev1527d_thl < _ev1527d_tp_min Or _
            _ev1527d_thl > _ev1527d_tp_max Then Jmp _ev1527d_capture1i_invalid

         #if _ev1527d_timing_strictness > 1

            If _ev1527d_th < _ev1527d_tph_min Or _
               _ev1527d_th > _ev1527d_tph_max Then Jmp _ev1527d_capture1i_invalid

         #endif

         #if _ev1527d_timing_strictness > 2

            _ev1527d_t_range(1) = _ev1527d_th * 20
            _ev1527d_t_range(2) = Th * 40
            If _ev1527d_thl < _ev1527d_t_range(1) Or _
               _ev1527d_thl > _ev1527d_t_range(2) Then Jmp _ev1527d_capture1i_invalid

         #endif

         Gosub _ev1527d_code_detected_unsafe
         Gosub _ev1527d_preamble_detected

      End If

      rjmp _ev1527d_Capture1i_exit

   _ev1527d_capture1i_invalid:

      _ev1527d_ivalidation = 0
      _ev1527d_safe_verify_counter = 0
      _ev1527d_match_verify_counter = 0
      'Reset Ot

   _ev1527d_capture1i_exit:

Return


_ev1527d_preamble_detected:

   _ev1527d_ivalidation = 1
   _ev1527d_ibit = 0
   _ev1527d_ibyte = 1
   _ev1527d_th_ref = _ev1527d_th / 2
   _ev1527d_buffer(1) = 0 : _ev1527d_buffer(2) = 0 : _ev1527d_buffer(3) = 0

Return

_ev1527d_code_detected_unsafe:

   If _ev1527d_status = _ev1527d_status_detect_mode Then
   'Detect Mode

      _ev1527d_ibyte = Memcopy(_ev1527d_buffer(1) , _ev1527d_code(1) , 3)
      Gosub _ev1527d_detected

   Elseif _ev1527d_status = _ev1527d_status_safe_mode Then
   'Safe Mode

      If _
         _ev1527d_buffer(1) = _ev1527d_previous_code(1) And _
         _ev1527d_buffer(2) = _ev1527d_previous_code(2) And _
         _ev1527d_buffer(3) = _ev1527d_previous_code(3) _
      Then

         If _ev1527d_safe_verify_counter >= _ev1527d_safe_mode_verify_count Then

           If _ev1527d_no_previous_match_ms >= _ev1527d_release_delay_ms Then

            _ev1527d_safe_verify_counter = 0
            _ev1527d_ibyte = Memcopy(_ev1527d_previous_code(1) , _ev1527d_code(1) , 3)

            _ev1527d_previous_code(1) = 0
            _ev1527d_previous_code(2) = 0
            _ev1527d_previous_code(3) = 0

            Gosub _ev1527d_safe_detected

           End If

           _ev1527d_no_previous_match_ms = 0

         Else

            Incr _ev1527d_safe_verify_counter

         End If


      Else

         _ev1527d_safe_verify_counter = 0
         _ev1527d_ibyte = Memcopy(_ev1527d_buffer(1) , _ev1527d_previous_code(1) , 3)

      End If

   Elseif _ev1527d_status = _ev1527d_status_match_mode Then
   'Match Mode

      _ev1527d_dummy_byte(1) = _ev1527d_buffer(3) And &HF0
      _ev1527d_dummy_byte(2) = _ev1527d_target_code(3) And &HF0

      If _
         _ev1527d_buffer(1) = _ev1527d_target_code(1) And _
         _ev1527d_buffer(2) = _ev1527d_target_code(2) And _
         _ev1527d_dummy_byte(1) = _ev1527d_dummy_byte(2) _
      Then

         If _ev1527d_match_verify_counter >= _ev1527d_match_mode_verify_count Then

           If _ev1527d_no_target_match_ms >= _ev1527d_release_delay_ms Then

            _ev1527d_match_verify_counter = 0
            _ev1527d_ibyte = Memcopy(_ev1527d_buffer(1) , _ev1527d_code(1) , 3)

            Gosub _ev1527d_match_detected

           End If

           _ev1527d_no_target_match_ms = 0

         Else

            Incr _ev1527d_match_verify_counter

         End If

      Else

         _ev1527d_match_verify_counter = 0

      End If

   End If

Return

_ev1527d_end: