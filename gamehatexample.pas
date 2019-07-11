program gamehatexample;

{
Tom Van den Bon - July 2019
Ultibo Example Code for using the GameHat from WaveShare
todo: audio
}

{$mode objfpc}{$H+}

{
Pins not used by GameHat

BCM2  (Pin3) SDA
BCM3  (Pin4) SCL
BCM14 (Pin8) UART TX
BCM15 (Pin10) UART RX
BCM17 (Pin11)
BCM27 (Pin13)
BCM22 (Pin15)
BCM24 (Pin18)
BCM25 (Pin22)
BCM10 (Pin19) MOSI
BCM9  (Pin21) MISO
BCM11 (Pin23) SCLK
BCM8  (Pin24) CE0
BCM7  (Pin26) CE1
BCM0  (Pin27) CE0
BCM1  (Pin28) CE1
}

uses
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  Console,
  Framebuffer,
  BCM2837,
  BCM2710,
  SysUtils,
  GPIO,
  Serial,
  Devices,
  math,
  SPI,
  MMC,
  HTTP,
  Winsock2,
  FileSystem,
  FATFS,
  SMSC95XX,
  DWCOTG,
  Shell,
  ShellFilesystem,
  ShellUpdate,
  RemoteShell;

const
  AmountButtons =  11;
  BTN_SELECT = 0;
  BTN_START = 1;
  BTN_A = 2;
  BTN_B = 3;
  BTN_X = 4;
  BTN_Y = 5;
  BTN_TL = 6;
  BTN_TR = 7;
  BTN_UP = 8;
  BTN_DOWN = 9;
  BTN_LEFT = 10;
  BTN_RIGHT = 11;

var
 CurrentValue:LongWord;
 WindowHandleDebug:TWindowHandle;
 WindowHandleSerial:TWindowHandle;

 SelectPressed : array[0..AmountButtons] of Byte;
 Buttons : array[0..AmountButtons] of LongWord;
 cnt : integer;
 Character:Char;
 Count:LongWord;
 Characters:String;
 ResultCode : LongWord;

 test : byte;
 testString : AnsiString;

 packetSize : integer;

procedure GPIOPinEvent(Data:Pointer;Pin,Trigger:LongWord);
var currentButton : Byte;
    i : Byte;
begin

  for i:= 0 to AmountButtons do
  begin
       if (Buttons[i] = Pin ) then
          currentButton := i;
  end;

  CurrentValue:=GPIOInputGet(Pin);

  if (CurrentValue = GPIO_LEVEL_LOW) and ( SelectPressed[currentButton] = 0 ) then
  begin
   SelectPressed[currentButton] := 1;
  end;

  if (CurrentValue = GPIO_LEVEL_HIGH) and (SelectPressed[currentButton] = 1) then
   begin
        SelectPressed[currentButton] := 2;
   end;

  GPIOInputEvent(Pin,GPIO_TRIGGER_EDGE,INFINITE,@GPIOPinEvent,nil);

end;


begin
 WindowHandleDebug:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_LEFT,True);
 WindowHandleSerial:=ConsoleWindowCreate(ConsoleDeviceGetDefault,CONSOLE_POSITION_RIGHT,True);

 ConsoleWindowWriteLn(WindowHandleDebug,'Gamehat Example');

 { setup buttons }
 Buttons[BTN_SELECT] := GPIO_PIN_4;  {select}
 Buttons[BTN_START] := GPIO_PIN_21;   {start}
 Buttons[BTN_A] := GPIO_PIN_26;       {button A}
 Buttons[BTN_B] := GPIO_PIN_12;       {button B}
 Buttons[BTN_X] := GPIO_PIN_16;       {button X}
 Buttons[BTN_Y] := GPIO_PIN_20;       {button Y}
 Buttons[BTN_TL] := GPIO_PIN_18;      {button TL}
 Buttons[BTN_TR] := GPIO_PIN_23;      {button TR}
 Buttons[BTN_UP] := GPIO_PIN_5;      {button UP}
 Buttons[BTN_DOWN] := GPIO_PIN_6;    {button DOWN}
 Buttons[BTN_LEFT] := GPIO_PIN_13;   {button LEFT}
 Buttons[BTN_RIGHT] := GPIO_PIN_19;  {button RIGHT}



 for cnt := 0 to AmountButtons do
 begin
    GPIOPullSelect(Buttons[cnt],GPIO_PULL_UP);
    GPIOFunctionSelect(Buttons[cnt],GPIO_FUNCTION_IN);
    {register edge trigger event on pin}
    GPIOInputEvent(Buttons[cnt],GPIO_TRIGGER_EDGE,INFINITE,@GPIOPinEvent,nil);
 end;


 { setup serial port }
 if SerialDeviceOpen(SerialDeviceGetDefault, 9600,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0) = ERROR_SUCCESS then
  begin
        ConsoleWindowWriteLn(WindowHandleDebug,'Serial Port Opened');
  end;

 Count:=0;


 while True do
  begin

     { check for serial port data }
     ResultCode := SerialDeviceRead(SerialDeviceGetDefault,@Character,SizeOf(Character),SERIAL_READ_NON_BLOCK, Count);

     if (ResultCode = ERROR_SUCCESS) or (ResultCode = ERROR_NO_MORE_ITEMS) and ( Count > 0 ) then
      begin
     if Character = #13 then
      begin
       ConsoleWindowWriteLn(WindowHandleSerial,'> ' + Characters);

       Characters:=Characters + Chr(13) + Chr(10);

       SerialDeviceWrite(SerialDeviceGetDefault,PChar(Characters),Length(Characters), SERIAL_WRITE_NONE, Count);

       Characters:='';
      end
     else
      begin
       Characters:=Characters + Character;
      end;
     end;


     if ( SelectPressed[BTN_START] = 2 ) then
     begin
          ConsoleWindowWriteLn(WindowHandleDebug,'Start!!');
     end;

     {check/reset button presses}
     for cnt:= 0 to AmountButtons do
     begin
          if ( cnt > 7 ) then {joystick}
           begin
           if ( SelectPressed[cnt] = 1) then
            begin
                 ConsoleWindowWriteLn(WindowHandleDebug,IntToStr(cnt) + ' Pressed');
            end;
           end;

          if ( SelectPressed[cnt] = 2) then
           begin
                ConsoleWindowWriteLn(WindowHandleDebug,IntToStr(cnt) + ' Pressed');
                SelectPressed[cnt] := 0;
           end;
     end;

     Sleep(10);
  end;

 ThreadHalt(0);
end.

