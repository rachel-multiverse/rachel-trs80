; =============================================================================
; TRS-80 GAME MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Draw the complete game screen
; -----------------------------------------------------------------------------
draw_game_screen:
        call    display_init

        ld      h, 26
        ld      l, 0
        call    set_cursor
        ld      hl, gm_title
        call    print_string

        ld      l, 1
        call    draw_border
        ld      l, 3
        call    draw_border
        ld      l, 7
        call    draw_border
        ld      l, 12
        call    draw_border
        ld      l, 14
        call    draw_border

        ld      h, 1
        ld      l, 8
        call    set_cursor
        ld      hl, gm_hand
        call    print_string

        ld      h, 1
        ld      l, 13
        call    set_cursor
        ld      hl, gm_ctrl
        call    print_string

        ret

gm_title:   defb    "RACHEL V1.0", 0
gm_hand:    defb    "YOUR HAND:", 0
gm_ctrl:    defb    "L/R=MOVE SPC=SEL RET=PLAY D=DRAW", 0

; -----------------------------------------------------------------------------
; Full game redraw
; -----------------------------------------------------------------------------
redraw_game:
        call    draw_players
        call    draw_discard
        call    draw_hand
        call    draw_turn_indicator
        ret

; =============================================================================
; PLAYER LIST
; =============================================================================

draw_players:
        ld      h, 0
        ld      l, 2
        call    set_cursor

        ld      a, 0
dp_loop1:
        ld      (dp_idx), a
        call    draw_one_player
        ld      a, (dp_idx)
        inc     a
        cp      4
        jr      c, dp_loop1

        ld      h, 32
        ld      l, 2
        call    set_cursor

        ld      a, 4
dp_loop2:
        ld      (dp_idx), a
        call    draw_one_player
        ld      a, (dp_idx)
        inc     a
        cp      8
        jr      c, dp_loop2

        ret

dp_idx: defb    0

draw_one_player:
        ld      a, 'P'
        call    print_char
        ld      a, (dp_idx)
        add     a, '1'
        call    print_char
        ld      a, ':'
        call    print_char

        ld      a, (dp_idx)
        ld      hl, PLAYER_COUNTS
        add     a, l
        ld      l, a
        jr      nc, dop_nc
        inc     h
dop_nc:
        ld      a, (hl)
        call    print_number_2d

        ld      a, ' '
        call    print_char
        ret

print_number_2d:
        ld      c, a
        ld      b, 0
pn2d_tens:
        cp      10
        jr      c, pn2d_print
        sub     10
        inc     b
        jr      pn2d_tens

pn2d_print:
        ld      c, a
        ld      a, b
        add     a, '0'
        call    print_char
        ld      a, c
        add     a, '0'
        call    print_char
        ret

; =============================================================================
; DISCARD PILE
; =============================================================================

draw_discard:
        ld      h, 26
        ld      l, 4
        call    set_cursor
        ld      hl, dd_lbl
        call    print_string

        ld      h, 28
        ld      l, 5
        call    set_cursor

        ld      a, (DISCARD_TOP)
        or      a
        jr      z, dd_empty
        call    print_card
        jr      dd_suit

dd_empty:
        ld      hl, dd_mt
        call    print_string
        ret

dd_suit:
        ld      a, (NOMINATED_SUIT)
        cp      $FF
        ret     z

        ld      h, 26
        ld      l, 6
        call    set_cursor
        ld      hl, dd_st_lbl
        call    print_string

        ld      a, (NOMINATED_SUIT)
        call    print_suit_name
        ret

dd_lbl:     defb    "DISCARD:", 0
dd_mt:      defb    "[EMPTY]", 0
dd_st_lbl:  defb    "SUIT: ", 0

print_suit_name:
        and     3
        add     a, a
        ld      hl, sn_ptrs
        add     a, l
        ld      l, a
        jr      nc, psn_nc
        inc     h
psn_nc:
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        call    print_string
        ret

sn_ptrs:    defw    sn_h, sn_d, sn_c, sn_s
sn_h:       defb    "HEARTS", 0
sn_d:       defb    "DIAMONDS", 0
sn_c:       defb    "CLUBS", 0
sn_s:       defb    "SPADES", 0

; =============================================================================
; HAND DISPLAY
; =============================================================================

draw_hand:
        ld      a, (HAND_COUNT)
        or      a
        jr      nz, dh_has_cards

        ld      h, 1
        ld      l, 9
        call    set_cursor
        ld      hl, dh_empty
        call    print_string
        ret

dh_has_cards:
        ld      h, 1
        ld      l, 9
        call    set_cursor

        xor     a
        ld      (dh_pos), a
        ld      (dh_col), a

dh_loop:
        ld      a, (dh_pos)
        call    check_selected
        or      a
        jr      z, dh_not_sel

        ld      a, '['
        call    print_char
        jr      dh_card

dh_not_sel:
        ld      a, (dh_pos)
        ld      b, a
        ld      a, (CURSOR_POS)
        cp      b
        jr      nz, dh_not_cur

        ld      a, '>'
        call    print_char
        jr      dh_card

dh_not_cur:
        ld      a, ' '
        call    print_char

dh_card:
        ld      a, (dh_pos)
        ld      hl, MY_HAND
        add     a, l
        ld      l, a
        jr      nc, dh_nc1
        inc     h
dh_nc1:
        ld      a, (hl)
        call    print_card

        ld      a, (dh_pos)
        call    check_selected
        or      a
        jr      z, dh_no_close
        ld      a, ']'
        call    print_char
        jr      dh_space
dh_no_close:
        ld      a, ' '
        call    print_char

dh_space:
        ld      a, (dh_pos)
        inc     a
        ld      (dh_pos), a

        ld      a, (dh_col)
        inc     a
        ld      (dh_col), a
        cp      10                      ; 10 cards per row for 64-col
        jr      nz, dh_no_newline

        xor     a
        ld      (dh_col), a

        ld      a, (dh_pos)
        rrca
        rrca
        rrca
        and     $1F
        add     a, 9
        ld      l, a
        ld      h, 1
        call    set_cursor

dh_no_newline:
        ld      a, (dh_pos)
        ld      b, a
        ld      a, (HAND_COUNT)
        cp      b
        jr      nz, dh_loop

        ret

dh_pos:     defb    0
dh_col:     defb    0
dh_empty:   defb    "(NO CARDS)", 0

; -----------------------------------------------------------------------------
; Check if card selected
; -----------------------------------------------------------------------------
check_selected:
        cp      8
        jr      nc, cks_high

        ld      b, a
        ld      a, (SELECTED_LO)
        jr      cks_shift

cks_high:
        sub     8
        ld      b, a
        ld      a, (SELECTED_HI)

cks_shift:
        inc     b
cks_sloop:
        dec     b
        jr      z, cks_test
        rrca
        jr      cks_sloop

cks_test:
        and     1
        ret

; =============================================================================
; TURN INDICATOR
; =============================================================================

draw_turn_indicator:
        ld      l, 15
        call    clear_row

        ld      h, 20
        ld      l, 15
        call    set_cursor

        ld      a, (CURRENT_TURN)
        ld      b, a
        ld      a, (MY_INDEX)
        cp      b
        jr      nz, dti_other

        ld      hl, dti_your
        call    print_string
        ret

dti_other:
        ld      hl, dti_player
        call    print_string

        ld      a, (CURRENT_TURN)
        add     a, '1'
        call    print_char

        ld      hl, dti_turn
        call    print_string
        ret

dti_your:   defb    ">>> YOUR TURN <<<", 0
dti_player: defb    "PLAYER ", 0
dti_turn:   defb    "'S TURN", 0
