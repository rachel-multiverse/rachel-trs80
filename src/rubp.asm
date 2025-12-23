; =============================================================================
; TRS-80 RUBP PROTOCOL MODULE
; Rachel UDP Binary Protocol - 64-byte fixed messages
; Message types defined in equates.asm
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize RUBP layer
; -----------------------------------------------------------------------------
rubp_init:
        xor     a
        ld      (rubp_seq), a
        ld      (last_recv_seq), a
        ret

rubp_seq:       defb    0
last_recv_seq:  defb    0

; -----------------------------------------------------------------------------
; Build message header
; Input: A = message type
; -----------------------------------------------------------------------------
build_header:
        ld      (msg_type_temp), a

        ; Magic "RACH"
        ld      hl, tx_buffer
        ld      (hl), 'R'
        inc     hl
        ld      (hl), 'A'
        inc     hl
        ld      (hl), 'C'
        inc     hl
        ld      (hl), 'H'

        ; Version 1.0
        ld      hl, tx_buffer+4
        ld      (hl), $01
        inc     hl
        ld      (hl), $00

        ; Message type
        ld      a, (msg_type_temp)
        ld      (tx_buffer+6), a

        ; Flags
        xor     a
        ld      (tx_buffer+7), a

        ; Sequence number (big-endian)
        ld      (tx_buffer+8), a
        ld      a, (rubp_seq)
        ld      (tx_buffer+9), a
        inc     a
        ld      (rubp_seq), a

        ; Player ID
        ld      hl, (player_id)
        ld      a, h
        ld      (tx_buffer+10), a
        ld      a, l
        ld      (tx_buffer+11), a

        ; Game ID
        ld      hl, (game_id)
        ld      a, h
        ld      (tx_buffer+12), a
        ld      a, l
        ld      (tx_buffer+13), a

        ; Reserved
        xor     a
        ld      (tx_buffer+14), a
        ld      (tx_buffer+15), a

        ret

msg_type_temp:  defb    0
player_id:      defw    0
game_id:        defw    0

; -----------------------------------------------------------------------------
; Send HELLO message with player name and platform ID
; -----------------------------------------------------------------------------
send_hello:
        ld      a, MSG_HELLO
        call    build_header

        ; Clear payload first
        ld      hl, tx_buffer+16
        ld      b, 48
        xor     a
sh_clear:
        ld      (hl), a
        inc     hl
        djnz    sh_clear

        ; Copy player name to payload bytes 0-15
        ld      hl, player_name
        ld      de, tx_buffer+16
        ld      b, 16
sh_name:
        ld      a, (hl)
        or      a
        jr      z, sh_name_done
        ld      (de), a
        inc     hl
        inc     de
        djnz    sh_name
sh_name_done:

        ; Platform ID at payload bytes 16-17 (big-endian)
        ; TRS-80 = 0x000A
        ld      a, PLATFORM_ID_HI
        ld      (tx_buffer+32), a       ; payload+16
        ld      a, PLATFORM_ID_LO
        ld      (tx_buffer+33), a       ; payload+17

        call    net_send
        ret

; Default player name
player_name:
        defb    "TRS-80", 0
        defs    9, 0                    ; Pad to 16 bytes

; -----------------------------------------------------------------------------
; Send READY message
; -----------------------------------------------------------------------------
send_ready:
        ld      a, MSG_READY
        call    build_header

        ; Clear payload
        ld      hl, tx_buffer+16
        ld      b, 48
        xor     a
sr_clear:
        ld      (hl), a
        inc     hl
        djnz    sr_clear

        call    net_send
        ret

; -----------------------------------------------------------------------------
; Send PLAY_CARDS message
; Input: B = number of cards, card_play_buf contains cards
; -----------------------------------------------------------------------------
send_play_cards:
        ld      a, b
        ld      (card_count_temp), a

        ld      a, MSG_PLAY_CARDS
        call    build_header

        ; Card count
        ld      a, (card_count_temp)
        ld      (tx_buffer+16), a

        ; Nominated suit ($FF = none)
        ld      a, (nominated_suit)
        ld      (tx_buffer+17), a

        ; Cards (up to 8)
        ld      a, (card_count_temp)
        ld      b, a
        ld      hl, card_play_buf
        ld      de, tx_buffer+18
spc_copy:
        ld      a, b
        or      a
        jr      z, spc_pad
        ld      a, (hl)
        ld      (de), a
        inc     hl
        inc     de
        dec     b
        jr      spc_copy

spc_pad:
        ; Pad to 8 cards
        ld      a, e
        sub     (tx_buffer+18) & $FF
        cp      8
        jr      nc, spc_clear_rest
        xor     a
spc_pad_loop:
        ld      (de), a
        inc     de
        ld      a, e
        sub     (tx_buffer+18) & $FF
        cp      8
        jr      c, spc_pad_loop

spc_clear_rest:
        ; Clear rest of payload
        ld      hl, tx_buffer+26
        ld      b, 38
        xor     a
spc_clear:
        ld      (hl), a
        inc     hl
        djnz    spc_clear

        call    net_send
        ret

card_count_temp:    defb    0
nominated_suit:     defb    $FF
card_play_buf:      defs    8, 0

; -----------------------------------------------------------------------------
; Send DRAW_CARD message
; -----------------------------------------------------------------------------
send_draw:
        ld      a, MSG_DRAW_CARD
        call    build_header

        ; Clear payload
        ld      hl, tx_buffer+16
        ld      b, 48
        xor     a
sd_clear:
        ld      (hl), a
        inc     hl
        djnz    sd_clear

        call    net_send
        ret

; -----------------------------------------------------------------------------
; Receive and process message
; Returns: A = message type, or 0 if no message
; Carry set if no message
; -----------------------------------------------------------------------------
receive_message:
        call    net_recv
        jr      c, rm_none

        ; Validate magic
        ld      hl, rx_buffer
        ld      a, (hl)
        cp      'R'
        jr      nz, rm_invalid
        inc     hl
        ld      a, (hl)
        cp      'A'
        jr      nz, rm_invalid
        inc     hl
        ld      a, (hl)
        cp      'C'
        jr      nz, rm_invalid
        inc     hl
        ld      a, (hl)
        cp      'H'
        jr      nz, rm_invalid

        ; Store sequence
        ld      a, (rx_buffer+9)
        ld      (last_recv_seq), a

        ; Return message type
        ld      a, (rx_buffer+6)
        or      a               ; Clear carry
        ret

rm_invalid:
rm_none:
        xor     a
        scf
        ret

; -----------------------------------------------------------------------------
; Process GAME_STATE message
; Updates local game state from rx_buffer
; -----------------------------------------------------------------------------
process_game_state:
        ; Current turn
        ld      a, (rx_buffer+16)
        ld      (CURRENT_TURN), a

        ; Direction
        ld      a, (rx_buffer+17)
        ld      (DIRECTION), a

        ; Discard top card
        ld      a, (rx_buffer+18)
        ld      (DISCARD_TOP), a

        ; Nominated suit
        ld      a, (rx_buffer+19)
        ld      (NOMINATED_SUIT), a

        ; Pending draws
        ld      a, (rx_buffer+20)
        ld      (PENDING_DRAWS), a

        ; Pending skips
        ld      a, (rx_buffer+21)
        ld      (PENDING_SKIPS), a

        ; Player counts (8 players)
        ld      hl, rx_buffer+22
        ld      de, PLAYER_COUNTS
        ld      bc, 8
        ldir

        ; My index
        ld      a, (rx_buffer+30)
        ld      (MY_INDEX), a

        ; My hand count
        ld      a, (rx_buffer+31)
        ld      (HAND_COUNT), a

        ; My hand (up to 16 cards)
        ld      hl, rx_buffer+32
        ld      de, MY_HAND
        ld      bc, 16
        ldir

        ret

; -----------------------------------------------------------------------------
; TX/RX Buffers
; -----------------------------------------------------------------------------
tx_buffer:      defs    64, 0
rx_buffer:      defs    64, 0
