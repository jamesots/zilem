Unit ZTest286;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#        286 Detection         #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

{$G-}

Interface

Implementation

{************************************************}
{                                                }
{ 286 Detection                                  }
{ Copyright (c) 1985,90 by Borland International }
{                                                }
{************************************************}

function Is286Able: Boolean; assembler;
asm
        PUSHF
        POP     BX
        AND     BX,0FFFH
        PUSH    BX
        POPF
        PUSHF
        POP     BX
        AND     BX,0F000H
        CMP     BX,0F000H
        MOV     AX,0
        JZ      @@1
        MOV     AX,1
@@1:
end; {of Is286Able}

Const
  SerialNumber : String[5] = 'Z0001';

Begin
  If not Is286Able then
  Begin
    Writeln('ZiLEM needs at least a 286 processor.');
    Halt(1);
  End else
  Writeln('ZiLEM (C) 1994 James Ots');
End. {of Unit ZTest286}
