; *********************************************************************************************************************
; Author:  Darren Bowles
; Date:    2020-05-03
; Purpose: This is just a test to help me learn coding Z80 on a ZX Spectrum
; shout out to Jonathan Cauldwell for their excellent tutorials and Allan Turvey of Happy Coding ZX for 
; inspiration from his live streaming warts n all coding session on Lunar Rescue conversion
; *********************************************************************************************************************


  device zxspectrum48
  
IM2_TABLE   = $FE00 ; IM2 interrupt vector table in decimal is 65024
IM2_VECTOR  = $FDFD ; IM2 interrupt vector in decimal is 65021
  

  org 32768             ; Set the origin of the program to 32768 (the start of the BASIC area)
  jp start              ; Jump to the start of the program

  include "library/doubleBufferAttributes.asm"
  include "library/colours.asm"
  include "music.asm"

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
  db right, 0,0, WHITE_PAPER
  db down, 0, 0, WHITE_PAPER
  db left, 31, 23, WHITE_PAPER
  db down, 31,0, WHITE_PAPER
  db up, 31, 23, WHITE_PAPER
  db right, 8,23, WHITE_PAPER
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
  db up, 4, 23, YELLOW_PAPER
  db up, 5, 23, YELLOW_PAPER
  db down, 10, 0, MAGENTA_PAPER
  db down, 11, 0, MAGENTA_PAPER
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
  jp myStart
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



; gameLoop - Main game loop
gameLoop:
  ; Wait for 2 ticks
.waitForTwoTicks:
  ; Load the previous timer value into HL
  ld hl, previousTimer

  ; Get the current timer value and subtract the previous timer value
  ld a, (23672)
  sub (hl)

  ; Check if we've waited for 2 ticks
.checkIfTwoTicksWaited:
  cp 3
  jr nc, .twoTicksWaited ; no more delay

      ; call loadNote

  ; If we haven't waited for 2 ticks yet, jump back to the start of the loop
  jp .waitForTwoTicks

.twoTicksWaited:
  ; If we've waited for 2 ticks, store the current timer value as the previous timer value
  ld a, (23672)
  ld (previousTimer), a



  ; set the border colour to black
  ld a, 0
  out (254), a


myStart:
  ; Loop through the aliens table and show each alien

  call loadNote
  ld ix, aliens
  ld b, numberOfAliens
  ld c, 0
.showAliensLoop:
  push bc

  call showAlien

  pop bc

  ; Move onto the next alien in the table
  ld de, 4 ; size of the table entry
  add ix, de
  djnz .showAliensLoop

.display:
  ; Copy the attributes buffer to the screen attributes
  call copyScreenAttributes

  ; Undraw the aliens (and move them)
  call undrawAliens

  ; Jump back to the start of the loop
  ;jp gameLoop
  jp myStart


; undrawAliens - Undraws the alien and then moves it
undrawAliens:
  ld ix, aliens ; Load the address of the aliens table into IX
  ld b, numberOfAliens ; Load the number of aliens into B
  ld c, 0 ; Initialize the loop counter

.loop:
  push bc ; Save the loop counter on the stack

  ; Get the address of the current alien
  call getAlienAddress

  ; Set the paper color to black to 'undraw' the alien
  ld a, BLACK_PAPER
  ld (hl), a

  ; Move the alien
  call moveAlien

  ; Check if the alien is within the screen bounds
  call checkBounds

  pop bc ; Restore the loop counter from the stack

  ; Move onto the next alien in the table
  ld de, 4 ; size of the table entry
  add ix, de
  djnz .loop ; Decrement B and jump back to the start of the loop if B is not zero

  ; Return from the subroutine
  ret

; showAlien - Displays the alien on the screen
showAlien:
  ; Get the address of the current alien
  call getAlienAddress

  ; Get the color of the alien from the table and put it in the buffer
  ld a, (ix+3)
  ld (hl), a

  ; Return from the subroutine
  ret

; getAlienAddress - Gets the address of the current alien in the attribute buffer
getAlienAddress:
  ; Check if the alien is disabled
  ld a, (ix) ; Load the status/direction byte into A
  cp 255 ; Check if it's equal to 255 (disabled)
  ret z ; If it's disabled, return

  ; Get the x and y coordinates of the alien
  ld b, (ix+1) ; Load the x coordinate into B
  ld c, (ix+2) ; Load the y coordinate into C

  ; Calculate the address of the alien in the attribute buffer
  call CalculateAttributeBufferAddress

  ; Return from the subroutine with the address in HL
  ret

; moveAlien - Moves the alien in the direction specified by its status byte
moveAlien:
  ; Check if the alien is moving up
  ld a, (ix)
  and up
  call nz, moveAlienUp

  ; Check if the alien is moving down
  ld a, (ix)
  and down
  call nz, moveAlienDown

  ; Check if the alien is moving left
  ld a, (ix)
  and left
  call nz, moveAlienLeft

  ; Check if the alien is moving right
  ld a, (ix)
  and right
  call nz, moveAlienRight

  ret

; moveAlienUp - Moves the alien up by decrementing its y coordinate
moveAlienUp:
  dec c ; Decrement the y coordinate
  ld (ix+2), c ; Store the new y coordinate in the aliens table
  ret

; moveAlienDown - Moves the alien down by incrementing its y coordinate
moveAlienDown:
  inc c ; Increment the y coordinate
  ld (ix+2), c ; Store the new y coordinate in the aliens table
  ret

; moveAlienLeft - Moves the alien left by decrementing its x coordinate
moveAlienLeft:
  dec b ; Decrement the x coordinate
  ld (ix+1), b ; Store the new x coordinate in the aliens table
  ret

; moveAlienRight - Moves the alien right by incrementing its x coordinate
moveAlienRight:
  inc b ; Increment the x coordinate
  ld (ix+1), b ; Store the new x coordinate in the aliens table
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

  ; play music here
  ; call loadNote

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