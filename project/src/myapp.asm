  device zxspectrum48
  
IM2_TABLE   = $FE00 ; IM2 interrupt vector table in decimal is 65024
IM2_VECTOR  = $FDFD ; IM2 interrupt vector in decimal is 65021
  

  org 32768             ; Set the origin of the program to 32768 (the start of the BASIC area)
  jp start              ; Jump to the start of the program

  include "library/doubleBufferAttributes.asm"
  include "library/colours.asm"

; store the previous timer value
previousTimer: defb 0

; directions
up: equ 1
down: equ 2
left: equ 4
right: equ 8

; well, just blobs of colour at the moment
; direction, x, y, colour
aliens:
  db right, 0,0, BLACK_PAPER
  db down, 0, 0, BLACK_PAPER
  db left, 31, 23, BLACK_PAPER
  db down, 31,0, BLACK_PAPER
  db up, 31, 23, BLACK_PAPER
  db right, 8,23, BLACK_PAPER
  db right + down, 15, 16, CYAN_PAPER  
  db left, 3,4, CYAN_PAPER
  db right, 1,2, CYAN_PAPER
  db right + down, 10, 10, CYAN_PAPER
  db down, 20, 20, CYAN_PAPER
  db up, 21,20, CYAN_PAPER
  db down + left, 32, 20, MAGENTA_PAPER
  db right + down, 5, 6  , CYAN_PAPER
  db left, 13,14, CYAN_PAPER
  db right, 11,22, CYAN_PAPER
  db right + down, 1, 1, CYAN_PAPER
  db down, 2, 2, CYAN_PAPER
  db up, 11,20, CYAN_PAPER
  db down + left, 22, 10, CYAN_PAPER
  db down + left, 32, 0, MAGENTA_PAPER
  db down + left, 30, 2, MAGENTA_PAPER
  db down + left, 28, 4, MAGENTA_PAPER
  db up, 4, 23, BLACK_PAPER
  db up, 5, 23, BLACK_PAPER
  db down, 10, 0, BLACK_PAPER
  db down, 11, 0, BLACK_PAPER
  db up, 15, 23, YELLOW_PAPER
  db up, 16, 23, YELLOW_PAPER
  db down, 17, 0, GREEN_PAPER
  db down, 18, 0, GREEN_PAPER
  db left, 32, 10, RED_PAPER
  db left, 32, 11, RED_PAPER
  db right, 0, 10, RED_PAPER
  db right, 0, 11, RED_PAPER
  db down, 15, 0, RED_PAPER
  db down, 16, 0, RED_PAPER
  db up, 15, 23, RED_PAPER
  db up, 16, 23, RED_PAPER
  db down + left, 28, 0, BLUE_PAPER
  db down + left, 29, 1, BLUE_PAPER
  db down + left, 30, 2, BLUE_PAPER

numberOfAliens: equ ($ - aliens) / 4

start:
  ; This section of code sets up the IM2 interrupt vector table and enables interrupts.

  ; Disable interrupts
  di

  ; Load the address of the IM2 interrupt vector table into DE
  ld de, IM2_TABLE

  ; Load the address of the IM2 interrupt handler into HL
  ld hl, IM2_VECTOR

  ; Load the value of D into A and set the interrupt mode to 2
  ld a,d
  ld i,a
  im 2

  ; Fill the IM2 interrupt vector table with the address of the IM2 interrupt handler
.fill_loop:
  ld a,l
  ld (de),a
  inc e
  jp nz, .fill_loop
  inc d
  ld (de), a

; Set the IM2 interrupt vector to point to the IM2 interrupt handler
  ld (hl),$c3
  inc l
  ld (hl),low im2_handler
  inc l
  ld (hl),high im2_handler

; Enable interrupts
  ei



gameLoop:

.wait:
  ld hl, previousTimer
  ld a, (23672) ; get the timer
  sub (hl) ; get the difference between current and previous timer

.keepWaiting2:
  cp 2; have we waited 2 ticks?
  jr nc, .wait0 ; no more delay

  jp .wait ; wait some more
.wait0:
  ld a, (23672) ; get the timer
  ld (previousTimer), a ; store

  ld a, 0
  out (254),a

  ld ix, aliens
  ld b, numberOfAliens
  ld c,0
.nextAlien:
  push bc

  call showAlien
  pop bc

  ld de, 4 ; size of the table entry
  add ix, de ; move onto next alien
  djnz .nextAlien

.display:
  call copyScreenAttributes
  call undrawAliens
  jp gameLoop

; undraws the alien and then moves it
undrawAliens:
  ld ix, aliens
  ld b, numberOfAliens
  ld c,0
.loop:
  push bc
  call getAlienAddress
  ld a, WHITE_PAPER
  ld (hl), a

  
  call moveAlien
  call checkBounds
  pop bc

  ld de, 4 ; size of the table entry
  add ix, de ; next alien
  djnz .loop

  ret

showAlien:
 call getAlienAddress

  ld a, (ix+3)
  ld (hl), a ; put it in the buffer

  ret

getAlienAddress:
  ld a, (ix) ; get the status / direction
  cp 255 ; is it disabled?
  ret z ; yes, return

  ld b, (ix+1) ; get x coordinate
  ld c, (ix+2) ; get y coordinate

  call CalculateAttributeBufferAddress
  ret

moveAlien:
  ld a, (ix)
  and up
  call nz, moveAlienUp

  ld a, (ix)
  and down
  call nz, moveAlienDown

  ld a, (ix)
  and left
  call nz, moveAlienLeft

  ld a, (ix)
  and right
  call nz, moveAlienRight

  ret

moveAlienUp:
  dec c
  ld (ix+2), c
  ret
moveAlienDown:
  inc c
  ld (ix+2), c
  ret
moveAlienLeft:
  dec b
  ld (ix+1), b
  ret
moveAlienRight:
  inc b
  ld (ix+1), b
  ret

checkBounds:
  ; the position is stored in bc
  ld a, (ix) ;  load the direction / status into D

.checkRight:
  ; are we going right
  bit 3, a
  jr z, .checkLeft
  ; if we are going right, check if we've hit the right boundary
  ld a, b ; load the X position into A
  cp 31                    ; compare with the right boundary
  jr nz, .checkLeft        ; if A < 31, we haven't hit the right boundary
  ld a, (ix)
  and 255 - right
  or left
  ld (ix), a
  

.checkLeft:
  ; are we going left
  ld a, (ix) ;  load the direction / status into D
  bit 2, a
  jr z, .checkUp
  ; if we are going left, check if we've hit the left boundary
  ld a, b ; load the X position into A
  cp 0
  jr nz, .checkUp
  ld a, (ix)
  and 255 - left
  or right
  ld (ix), a
    
.checkUp:
  ; are we going up
  ld a, (ix) ;  load the direction / status into D
  bit 0, a
  jr z, .checkDown
  ; if we are going up, check if we've hit the top boundary
  ld a, c
  cp 0
  jr nz, .checkDown
  ld a, (ix)
  and 255 - up
  or down
  ld (ix), a
  jp .done

.checkDown:
  ; are we going down
  ld a, (ix) ;  load the direction / status into D
  bit 1, a
  jr z, .done
  ; if we are going down, check if we've hit the bottom boundary
  ld a, c
  cp 23                    ; compare with the bottom boundary
  jr nz, .done             ; if A < 23, we haven't hit the bottom boundary
  ld a, (ix)
  and 255 - down
  or up
  ld (ix), a
.done:
  ret


  cp 31                    ; compare with the right boundary
  jr nc, hitRightBoundary  ; if A >= 31, we've hit the right boundary
  or a                     ; check if A is 0 (the left boundary)
  jr z, hitLeftBoundary    ; if A == 0, we've hit the left boundary
checkUpperLowerScreenBounds:
                     ; move to Y position in memory
  ld a, c               ; load the Y position into A
  cp 23                    ; compare with the bottom boundary
  jr nc, hitBottomBoundary ; if A >= 23, we've hit the bottom boundary
  or a                     ; check if A is 0 (the top boundary)
  jr z, hitTopBoundary     ; if A == 0, we've hit the top boundary

  ret

hitTopBoundary:  
  ld a, (ix)

  bit 0, a            ; Check if the "down" bit is set in A.
  ret z  ; If the "down" bit is not set, we don't need to change the direction.


  and 255 - up
  or down
  ld (ix), a
  ret

; This function is called when the alien hits the bottom boundary of the screen.
; It plays a sound effect, changes the direction of the alien to move up, and returns.

hitBottomBoundary:
  ld a, (ix)          ; Load the current direction of the alien into A.
  
  bit 1, a            ; Check if the "down" bit is set in A.
  ret z  ; If the "down" bit is not set, we don't need to change the direction.


  and 255 - down      ; Clear the "down" bit in A by ANDing it with the bitwise complement of "down".
  or up               ; Set the "up" bit in A by ORing it with "up".
  ld (ix), a          ; Store the new direction back into memory.
  ret                 ; Return from the function.

hitLeftBoundary:
  ld a, (ix)
  bit 3,a
  jp z, checkUpperLowerScreenBounds ; If the "left" bit is not set, we don't need to change the direction.
  and 255 - left
  or right
  ld (ix), a
  jp checkUpperLowerScreenBounds
  ret
hitRightBoundary:
  ld a, (ix)

  bit 4, a ; Check if the "right" bit is set in A.
  jp z, checkUpperLowerScreenBounds ; If the "right" bit is not set, we don't need to change the direction.

  and 255 - right
  or left
  ld (ix), a
  jp checkUpperLowerScreenBounds
  ret

im2_handler:
  push af
  push bc
  push de
  push hl
  ex af,af'
  exx
  push af
  push bc
  push de
  push hl
  push ix
  push iy

  ; Update screen attributes here
  ; ld hl, attrBuffer ; Load address of attribute buffer into HL register pair
  ; ld de, $5800 ; Load address of screen attributes into DE register pair
  ; ld bc, 768 ; Load number of bytes to copy into BC register pair
  ; ldir ; Copy bytes from attribute buffer to screen attributes


  ;rst 56 ; read the keys and update clock
  ld hl, (23672)
  inc hl
  ld (23672), hl
  ld a,h
  or l

  ; ^^ this is the same as rst 56

  pop iy
  pop ix
  pop hl
  pop de
  pop bc
  pop af
  ex af,af'
  exx
  pop hl
  pop de
  pop bc
  pop af
  ei
  ret


; Deployment
  savesna "myapp.sna",start  ; Save the program as a snapshot file