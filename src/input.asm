; =============================================================================
; TRS-80 INPUT MODULE
; =============================================================================

; -----------------------------------------------------------------------------
; Wait for key (blocking)
; Returns: A = key code
; -----------------------------------------------------------------------------
wait_key:
wk_loop:
        call    scan_keyboard
        or      a
        jr      z, wk_loop
        ret

; -----------------------------------------------------------------------------
; Check for key (non-blocking)
; Returns: A = key if pressed, 0 if no key
; -----------------------------------------------------------------------------
check_key:
        call    scan_keyboard
        ret

; -----------------------------------------------------------------------------
; Scan keyboard matrix
; Returns: A = key code or 0
; -----------------------------------------------------------------------------
scan_keyboard:
        ld      hl, KBDRAM
        ld      b, 8                    ; 8 rows

sk_row:
        ld      a, (hl)
        or      a
        jr      nz, sk_decode
        inc     hl
        djnz    sk_row
        xor     a
        ret

sk_decode:
        ; Simple decode - return first key found
        ; Row in B (8 - remaining), bits in A
        ld      c, a
        ld      a, 8
        sub     b                       ; Row number (0-7)

        ; Calculate key code from row and column
        sla     a
        sla     a
        sla     a                       ; Row * 8

        ld      d, 0
sk_bit:
        srl     c
        jr      c, sk_found
        inc     d
        jr      sk_bit

sk_found:
        add     a, d                    ; Key index
        ld      hl, key_table
        add     a, l
        ld      l, a
        jr      nc, sk_nc
        inc     h
sk_nc:
        ld      a, (hl)
        ret

; Key lookup table (simplified)
key_table:
        defb    '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G'
        defb    'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'
        defb    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W'
        defb    'X', 'Y', 'Z', 0, 0, 0, 0, 0
        defb    '0', '1', '2', '3', '4', '5', '6', '7'
        defb    '8', '9', ':', ';', ',', '-', '.', '/'
        defb    KEY_RETURN, 0, KEY_BREAK, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE
        defb    0, 0, 0, 0, 0, 0, 0, 0

; -----------------------------------------------------------------------------
; Input line
; Input: HL = buffer, B = max length
; Returns: A = length entered
; -----------------------------------------------------------------------------
input_line:
        ld      c, 0                    ; Current length

il_loop:
        call    wait_key

        cp      KEY_RETURN
        jr      z, il_done

        cp      KEY_LEFT
        jr      z, il_delete

        ; Check max
        ld      a, c
        cp      b
        jr      nc, il_loop

        call    wait_key                ; Get key again
        cp      ' '
        jr      c, il_loop
        cp      $7F
        jr      nc, il_loop

        ld      (hl), a
        inc     hl
        inc     c
        call    print_char
        jr      il_loop

il_delete:
        ld      a, c
        or      a
        jr      z, il_loop

        dec     hl
        dec     c

        push    hl
        ld      hl, (cursor_addr)
        dec     hl
        ld      (hl), ' '
        ld      (cursor_addr), hl
        pop     hl

        jr      il_loop

il_done:
        xor     a
        ld      (hl), a
        ld      a, c
        ret
