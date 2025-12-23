; =============================================================================
; RACHEL TRS-80 CLIENT - Main Entry Point
; =============================================================================
; TRS-DOS .CMD format - loads at $5200

        org     $5200

        include "equates.asm"

; =============================================================================
; ENTRY POINT
; =============================================================================

main:
        call    display_init
        call    draw_title_screen
        call    wait_key

main_connect:
        call    display_init
        call    input_ip_address
        call    do_connect
        or      a
        jr      nz, main_connect        ; Retry on failure

        call    wait_for_game
        or      a
        jr      nz, main_connect        ; Back to connect on cancel

        call    draw_game_screen

main_loop:
        call    net_available
        or      a
        jr      z, ml_input

        call    rubp_receive
        call    rubp_validate
        or      a
        jr      nz, ml_input

        call    rubp_get_type

        cp      MSG_GAME_STATE
        jr      nz, ml_chk_end
        call    rubp_parse_game_state
        call    redraw_game
        jr      ml_input

ml_chk_end:
        cp      MSG_GAME_END
        jr      nz, ml_input
        call    draw_game_end
        call    wait_key
        jp      main_connect

ml_input:
        ld      a, (CURRENT_TURN)
        ld      b, a
        ld      a, (MY_INDEX)
        cp      b
        jp      nz, main_loop           ; Not our turn

        call    check_key
        or      a
        jp      z, main_loop

        cp      KEY_LEFT
        jr      z, ml_left
        cp      KEY_RIGHT
        jr      z, ml_right
        cp      KEY_SPACE
        jr      z, ml_select
        cp      KEY_RETURN
        jr      z, ml_play
        cp      KEY_D
        jr      z, ml_draw
        cp      KEY_d
        jr      z, ml_draw
        cp      KEY_BREAK
        jr      z, ml_quit

        jp      main_loop

ml_left:
        ld      a, (CURSOR_POS)
        or      a
        jp      z, main_loop
        dec     a
        ld      (CURSOR_POS), a
        call    draw_hand
        jp      main_loop

ml_right:
        ld      a, (CURSOR_POS)
        inc     a
        ld      b, a
        ld      a, (HAND_COUNT)
        cp      b
        jp      z, main_loop
        jp      c, main_loop
        ld      a, b
        ld      (CURSOR_POS), a
        call    draw_hand
        jp      main_loop

ml_select:
        call    toggle_selected
        call    draw_hand
        jp      main_loop

ml_play:
        call    count_selected
        or      a
        jp      z, main_loop            ; Nothing selected

        call    check_needs_nomination
        or      a
        jr      z, ml_no_nom

        call    get_suit_nomination
        jr      ml_send_play

ml_no_nom:
        ld      a, $FF                  ; No nomination

ml_send_play:
        call    rubp_send_play_card
        xor     a
        ld      (SELECTED_LO), a
        ld      (SELECTED_HI), a
        jp      main_loop

ml_draw:
        ld      a, 1
        call    rubp_send_draw_card
        jp      main_loop

ml_quit:
        call    net_close
        jp      main_connect

; =============================================================================
; TITLE SCREEN
; =============================================================================

draw_title_screen:
        ld      h, 26
        ld      l, 3
        call    set_cursor
        ld      hl, title_1
        call    print_string

        ld      h, 23
        ld      l, 5
        call    set_cursor
        ld      hl, title_2
        call    print_string

        ld      h, 24
        ld      l, 7
        call    set_cursor
        ld      hl, title_3
        call    print_string

        ld      h, 24
        ld      l, 10
        call    set_cursor
        ld      hl, title_4
        call    print_string

        ld      h, 23
        ld      l, 14
        call    set_cursor
        ld      hl, title_5
        call    print_string

        ret

title_1:
        defb    "RACHEL", 0
title_2:
        defb    "THE CARD GAME", 0
title_3:
        defb    "TRS-80 CLIENT", 0
title_4:
        defb    "TRS-IO REQUIRED", 0
title_5:
        defb    "PRESS ANY KEY", 0

; =============================================================================
; GAME END SCREEN
; =============================================================================

draw_game_end:
        ld      h, 23
        ld      l, 8
        call    set_cursor
        ld      hl, end_msg
        call    print_string
        ret

end_msg:
        defb    "*** GAME OVER ***", 0

; =============================================================================
; TOGGLE CARD SELECTION
; =============================================================================

toggle_selected:
        ld      a, (CURSOR_POS)
        cp      8
        jr      nc, ts_high

        ld      b, a
        ld      a, 1
        or      a
        jr      z, ts_do_lo
ts_shift_lo:
        dec     b
        jr      z, ts_do_lo
        add     a, a
        jr      ts_shift_lo
ts_do_lo:
        ld      b, a
        ld      a, (SELECTED_LO)
        xor     b
        ld      (SELECTED_LO), a
        ret

ts_high:
        sub     8
        ld      b, a
        ld      a, 1
        inc     b
ts_shift_hi:
        dec     b
        jr      z, ts_do_hi
        add     a, a
        jr      ts_shift_hi
ts_do_hi:
        ld      b, a
        ld      a, (SELECTED_HI)
        xor     b
        ld      (SELECTED_HI), a
        ret

; =============================================================================
; CHECK IF NOMINATION NEEDED
; =============================================================================

check_needs_nomination:
        ld      a, (SELECTED_LO)
        ld      c, a
        ld      a, (SELECTED_HI)
        ld      b, a
        ld      de, MY_HAND
        ld      a, (HAND_COUNT)
        or      a
        ret     z

        ld      h, a
cnn_loop:
        ld      a, c
        and     1
        jr      z, cnn_next

        ld      a, (de)
        and     $0F
        cp      RANK_ACE
        jr      z, cnn_yes

cnn_next:
        srl     b
        rr      c
        inc     de
        dec     h
        jr      nz, cnn_loop

        xor     a
        ret

cnn_yes:
        ld      a, 1
        ret

; =============================================================================
; GET SUIT NOMINATION
; =============================================================================

get_suit_nomination:
        ld      h, 1
        ld      l, 14
        call    set_cursor
        ld      hl, nom_prompt
        call    print_string

gsn_wait:
        call    wait_key
        cp      'H'
        jr      z, gsn_hearts
        cp      'h'
        jr      z, gsn_hearts
        cp      'D'
        jr      z, gsn_diamonds
        cp      'd'
        jr      z, gsn_diamonds
        cp      'C'
        jr      z, gsn_clubs
        cp      'c'
        jr      z, gsn_clubs
        cp      'S'
        jr      z, gsn_spades
        cp      's'
        jr      z, gsn_spades
        jr      gsn_wait

gsn_hearts:
        ld      a, SUIT_HEARTS
        ret
gsn_diamonds:
        ld      a, SUIT_DIAMONDS
        ret
gsn_clubs:
        ld      a, SUIT_CLUBS
        ret
gsn_spades:
        ld      a, SUIT_SPADES
        ret

nom_prompt:
        defb    "SUIT? H/D/C/S: ", 0

; =============================================================================
; HELPER FUNCTIONS
; =============================================================================

; Input IP address from user
input_ip_address:
        call    get_server_address
        ret

; Perform connection
do_connect:
        call    show_connecting
        ld      hl, server_ip
        ld      de, (conn_port)
        call    connect_server
        jr      c, dc_fail
        ; Send HELLO with player name and platform ID
        call    rubp_init
        call    send_hello
        xor     a
        ret
dc_fail:
        call    show_connect_error
        ld      a, 1
        ret

; Wait for game to start
wait_for_game:
        ld      h, 20
        ld      l, 12
        call    set_cursor
        ld      hl, wfg_msg
        call    print_string
wfg_loop:
        call    check_key
        cp      KEY_BREAK
        jr      z, wfg_cancel
        call    net_recv
        jr      c, wfg_loop
        call    receive_message
        cp      MSG_GAME_START
        jr      nz, wfg_loop
        xor     a
        ret
wfg_cancel:
        ld      a, 1
        ret

wfg_msg:
        defb    "WAITING FOR GAME...", 0

; Check if network data available
net_available:
        push    hl
        in      a, (TRSIO_STATUS)
        and     STAT_DATA_AVAIL
        pop     hl
        ret

; RUBP receive wrapper
rubp_receive:
        call    net_recv
        ret

; Validate RUBP message
rubp_validate:
        ld      a, (rx_buffer)
        cp      'R'
        jr      nz, rv_bad
        ld      a, (rx_buffer+1)
        cp      'A'
        jr      nz, rv_bad
        ld      a, (rx_buffer+2)
        cp      'C'
        jr      nz, rv_bad
        ld      a, (rx_buffer+3)
        cp      'H'
        jr      nz, rv_bad
        xor     a
        ret
rv_bad:
        ld      a, 1
        ret

; Get message type
rubp_get_type:
        ld      a, (rx_buffer+6)
        ret

; Parse game state from buffer
rubp_parse_game_state:
        call    process_game_state
        ret

; Count selected cards
count_selected:
        ld      a, (SELECTED_LO)
        ld      c, a
        ld      a, (SELECTED_HI)
        ld      b, a
        xor     a
        ld      d, 16
cs_count:
        srl     b
        rr      c
        jr      nc, cs_next
        inc     a
cs_next:
        dec     d
        jr      nz, cs_count
        ret

; Send play card message
rubp_send_play_card:
        ld      (nominated_suit), a
        call    count_selected
        ld      b, a
        call    send_play_cards
        ret

; Send draw card message
rubp_send_draw_card:
        call    send_draw
        ret

; =============================================================================
; INCLUDES
; =============================================================================

        include "display.asm"
        include "input.asm"
        include "game.asm"
        include "connect.asm"
        include "rubp.asm"
        include "net/trsio.asm"

; =============================================================================
; DATA SECTION
; =============================================================================

CONN_STATE:     defb    0
CURRENT_TURN:   defb    0
DIRECTION:      defb    1
DISCARD_TOP:    defb    0
NOMINATED_SUIT: defb    $FF
DECK_COUNT:     defb    52
PENDING_DRAWS:  defb    0
PENDING_SKIPS:  defb    0
PLAYER_COUNT:   defb    0
MY_INDEX:       defb    0

HAND_COUNT:     defb    0
CURSOR_POS:     defb    0
SELECTED_LO:    defb    0
SELECTED_HI:    defb    0

PLAYER_ID_HI:   defb    0
PLAYER_ID_LO:   defb    0
GAME_ID_HI:     defb    0
GAME_ID_LO:     defb    0
SEQUENCE_HI:    defb    0
SEQUENCE_LO:    defb    0

PLAYER_COUNTS:  defs    8, 0

MY_HAND:        defs    32, 0
IP_INPUT_BUF:   defs    32, 0
SERIAL_TX_BUF:  defs    64, 0
SERIAL_RX_BUF:  defs    64, 0

        end     main
