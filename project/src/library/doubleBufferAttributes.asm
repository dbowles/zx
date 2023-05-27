; *********************************************************************************************************************
; Author:  Darren Bowles
; Date:    2020-05-03
; Purpose: This is a simple example of how to do double buffering with the screen attributes
; It's the same style that Jonathan Cauldwell mentions as being used in Rallybug
; see https://chuntey.wordpress.com/tag/double-buffering/ apart from i'm not doing screen memory (yet)
; and it's using some sjasmplus macros
; *********************************************************************************************************************

; we'll need to keep a copy of the stack pointer, as we'll be moving it around
CopyOfStackPointer: defw 0

    ; this macro copies over the screen attributes from the attribute buffer to the screen
    macro DoCopy row, columnStart
        ; we move the stack pointer to our attribute buffer, with our offset row and columnStart
        ld sp, AttributeBuffer + (row * 32) + columnStart
        ; now we start popping the attributes off the 'stack'
        pop af                      ; 1,0
        pop bc                      ; 3,2
        pop de                      ; 5,4
        pop hl                      ; 7,6

        ; oops, we've run out of registers, so we need to swap to alternate registers
        ex af, af'                  ; swap af with af'
        exx

        ; carry on popping
        pop af                      ; 9,8
        pop bc                      ; 11,10
        pop de                      ; 13,12
        pop hl                      ; 15,14

        ; we move the stack pointer to the attribute screen memory, with our offset row and columnStart
        ; as well as including the 16 bytes that we popped off the buffer stack and stored
        ld sp, $5800 + (row * 32) + columnStart + 16

        ; we push back onto the screen memory stack in reverse order
        push hl                     ; copy 15,14 to the screen memory
        push de                     ; copy 13,12 to the screen memory
        push bc                     ; copy 11,10 to the screen memory
        push af                     ; copy 9,8 to the screen memory

        ; swap back to the original registers
        ex af, af'                  
        exx

        push hl                     ; copy 7,6 to the screen memory
        push de                     ; copy 5,4 to the screen memory
        push bc                     ; copy 3,2 to the screen memory
        push af                     ; copy 1,0 to the screen memory
    endm

    ; this macro copies over a number of rows
    macro BufferCopyMacro count
        rept count, i
            DoCopy i, 0   ; copy the first 16 attributes over to the row
            DoCopy i, 16  ; copy the remaining 16 attributes over to the row
        endr
    endm

    ; this macro generates the lookup table for the attribute buffer
    macro AttributeBufferLookupMacro count
        rept count, i
            defw AttributeBuffer + (32 * i)
        endr
    endm

; here's our buffer - let's initialise it to all white paper, black ink
AttributeBuffer:
    block 768, STABLE + DULL + WHITE_PAPER + BLACK_INK

; here's our lookup table
AttributeBufferLookup:
    AttributeBufferLookupMacro 24; 
   

; CalculateAttributeBufferAddress - Calculates the attribute buffer address for a given position (X, Y)
;
; Input:
;   B: X coordinate (0-31)
;   C: Y coordinate (0-23)
;
; Output:
;   HL: Attribute Buffer address
;
CalculateAttributeBufferAddress:
  ; Load the address of the lookup table into HL
  ld hl, AttributeBufferLookup 

  ; Double the Y coordinate by adding it to itself
  ld a, c
  add a, a
  add a, l
  ld l, a

  ; Get the table address for the Y coordinate
  ld de, (hl)

  ; Add the X coordinate (in register B) to the table address (in register E)
  ld a, b
  add a, e
  ld e, a

  ; Check if we got a carry (i.e. we exceeded 255)
  jr nc, .noCarry

  ; If we got a carry, increment the high byte of the address
  inc d
  
.noCarry:
  ; Move the combined address into HL
  ld hl, de

  ; Return from the subroutine
  ret


; Copy the attributes buffer to the screen attributes
; TODO: This is a crude implementation that copies the entire buffer. 
; A more efficient implementation is possible.
copyScreenAttributes:
  ; Save the current stack pointer to memory
  ld (CopyOfStackPointer), sp

  ; Call the "BufferCopyMacro" macro to copy the buffer
  BufferCopyMacro 24

  ; Restore the stack pointer from memory
  ld sp, (CopyOfStackPointer)

  ; Return from the subroutine
  ret                    
