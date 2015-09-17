Unit ZDisk;

{################################}
{#      ZiLEM Z80 Emulator      #}
{#        Disk emulator         #}
{# Copyright (c) 1994 James Ots #}
{#      All rights reserved     #}
{################################}

Interface

Uses
  ZConsts;

Type
  PCreateDiskDialog = ^TCreateDiskDialog;
  TCreateDiskDialog = Object(TDialog)
    Constructor Init;
  End;

Implementation

Constructor TCreateDiskDialog.Init;

Begin
End;

End.

Const
  zdCreate = 1;
  zdOpen = 0;

Type
  DiskInfoRec = Record
    Sector, Cylinder, Side : Byte;
    SectorSize : Word;
  End;

  PZDisk = ^TZDisk;
  TZDisk = Object(TObject);
    DiskInfo : DiskInfoRec;
    DMA : Word;
    PZMem : Pointer;
    DiskStream : TDosStream;
    Procedure ReadSector;
    Procedure WriteSector;
    Constructor Init(Name : String; Mode : Byte); virtual;
    Destructor Done; virtual;
    Procedure Format;
  End;

Const
  DiskInfoSize : SizeOf(DiskInfoRec);

Constructor Init(Name : String; Mode : Byte; ADiskInfo : DiskInfoRec);

Begin
  Inherited Init;
  DiskInfo := ADiskInfo;
  Case Mode of
    zdCreate :
      DiskStream := New(TDosStream,Init(Name,stCreate));
      Format;
    zdOpen :
      DiskStream := New(TDosStream,Init(Name,stOpen));
  End;
End;

Procedure Format;

Var
  AByte : Byte;

Begin
  DiskStream^.Seek(0);
  DiskStream^.Write(DiskInfo,DiskInfoSize);
  DiskStream^.Seek(DiskInfoSize+DiskInfo.Sector*DiskInfo.Cylinder*DiskInfo.Side*DiskInfo.SectorSize);
  DiskStream^.Write(AByte,1);
End;
