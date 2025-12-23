; =============================================================================
; TRS-80 DISPLAY MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Initialize display
; -----------------------------------------------------------------------------
display_init:
        call    clear_screen
        ret

; -----------------------------------------------------------------------------
; Clear screen
; -----------------------------------------------------------------------------
clear_screen:
        ld      hl, VIDEO_BASE
        ld      bc, VIDEO_WIDTH * VIDEO_HEIGHT
        ld      a, ' '
cls_loop:
        ld      (hl), a
        inc     hl
        dec     bc
        ld      a, b
        or      c
        jr      nz, cls_loop
        ret

; -----------------------------------------------------------------------------
; Set cursor position
; Input: H = column (0-63), L = row (0-15)
; -----------------------------------------------------------------------------
set_cursor:
        push    af
        push    de

        ; Calculate address: VIDEO_BASE + row * 64 + col
        ld      a, l
        ld      d, 0
        ld      e, a

        ; Multiply row by 64
        sla     e
        rl      d               ; *2
        sla     e
        rl      d               ; *4
        sla     e
        rl      d               ; *8
        sla     e
        rl      d               ; *16
        sla     e
        rl      d               ; *32
        sla     e
        rl      d               ; *64

        ; Add column
        ld      a, h
        add     a, e
        ld      e, a
        ld      a, d
        adc     a, 0
        ld      d, a

        ; Add base address
        ld      hl, VIDEO_BASE
        add     hl, de

        ld      (cursor_addr), hl

        pop     de
        pop     af
        ret

cursor_addr:
        defw    VIDEO_BASE

; -----------------------------------------------------------------------------
; Print character at cursor
; Input: A = character
; -----------------------------------------------------------------------------
print_char:
        push    hl
        ld      hl, (cursor_addr)
        ld      (hl), a
        inc     hl
        ld      (cursor_addr), hl
        pop     hl
        ret

; -----------------------------------------------------------------------------
; Print null-terminated string
; Input: HL = string address
; -----------------------------------------------------------------------------
print_string:
        push    de
        ld      de, (cursor_addr)
ps_loop:
        ld      a, (hl)
        or      a
        jr      z, ps_done
        ld      (de), a
        inc     hl
        inc     de
        jr      ps_loop
ps_done:
        ld      (cursor_addr), de
        pop     de
        ret

; -----------------------------------------------------------------------------
; Clear a row
; Input: L = row number
; -----------------------------------------------------------------------------
clear_row:
        ld      h, 0
        call    set_cursor
        ld      b, VIDEO_WIDTH
        ld      a, ' '
        ld      hl, (cursor_addr)
cr_loop:
        ld      (hl), a
        inc     hl
        djnz    cr_loop
        ret

; -----------------------------------------------------------------------------
; Draw horizontal border
; Input: L = row number
; -----------------------------------------------------------------------------
draw_border:
        ld      h, 0
        call    set_cursor
        ld      b, VIDEO_WIDTH
        ld      a, '-'
        ld      hl, (cursor_addr)
db_loop:
        ld      (hl), a
        inc     hl
        djnz    db_loop
        ret

; -----------------------------------------------------------------------------
; Print a card
; Input: A = card byte
; -----------------------------------------------------------------------------
print_card:
        push    bc

        ld      c, a                    ; Save card

        and     $0F
        ld      hl, rank_chars
        add     a, l
        ld      l, a
        jr      nc, pc_nc1
        inc     h
pc_nc1:
        ld      a, (hl)
        call    print_char

        ld      a, c
        rrca
        rrca
        rrca
        rrca
        and     $03
        ld      hl, suit_chars
        add     a, l
        ld      l, a
        jr      nc, pc_nc2
        inc     h
pc_nc2:
        ld      a, (hl)
        call    print_char

        pop     bc
        ret

rank_chars:
        defb    "?A23456789TJQK"

suit_chars:
        defb    "HDCS"
