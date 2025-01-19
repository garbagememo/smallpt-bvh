program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

uses SysUtils,Classes,Math,uVect,uScene,uBMP,uHybrid,getopts;

var
  x,y,sx,sy,i,s: integer;
  w,h,samps,modelnum    : integer;
  temp,d       : Vec3;
  r1,r2,dx,dy  : real;
  tempRay  : RayRecord;
  cam:CamRecord;
  cx,cy: Vec3;
  tColor,r,camPosition,camDirection : Vec3;

  BMP:BMPRecord;

  vColor:rgbColor;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
  a:IntegerArray;
  HybridBVH:HybridBVHClass;

begin
  FN:='temp.bmp';
  w:=640 ;h:=480;  samps := 16;
  c:=#0;modelnum:=0;
  repeat
    c:=getopt('m:o:s:w:');

    case c of
      'm' : begin
         ArgInt:=StrToInt(OptArg);
         if modelnum<6 then modelnum:=ArgInt;     
      end;
      'o' : begin
         ArgFN:=OptArg;
         if ArgFN<>'' then FN:=ArgFN;
         writeln ('Output FileName =',FN);
      end;
      's' : begin
        ArgInt:=StrToInt(OptArg);
        samps:=ArgInt;
        writeln('samples =',ArgInt);
      end;
      'w' : begin
         ArgInt:=StrToInt(OptArg);
         w:=ArgInt;h:=w *3 div 4;
         writeln('w=',w,' ,h=',h);
      end;
      '?',':' : begin
         writeln(' -m [1..5] scene model ');
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
         halt;
      end;
    end; { case }
  until c=endofoptions;

  BMP.new(w,h);
  writeln('BMP=OK');

  Randomize;
  case modelnum of
     5:begin
          cam:=RandomScene;
       end;
     4:cam:=WadaScene;
     3:cam:=ForestScene;
     2:cam:=SkyScene;
     1:cam:=InitNEScene;
     else begin
        cam:=InitScene;
     end;
  end;(*case*)

  writeln('Model Number=',modelnum);
  writeln('Set Scene');
  writeln('samples=',samps);
  writeln('Wide x High=',w,' x ',h);

  SetLength(a,sph.count);
  for i:=0 to sph.count-1 do a[i]:=i;
  HybridBVH:=HybridBVHClass.Create(cam.p);

  cx.new(w * 0.5135 / h, 0, 0);
  cy:= (cx/ cam.d).norm;
  cy:= cy* 0.5135;

  writeln ('The time is : ',TimeToStr(Time));
(*
  cam.p:=vp.new(55, 58, 245.6);
  cam.d:=vd.new(0, -0.24, -1.0).norm;
  cam.PlaneDist:=140;  
*)
  
  for y := 0 to h-1 do begin
    if y mod 10 =0 then writeln('y=',y);
    for x := 0 to w - 1 do begin
      r:=ZeroVec;
      tColor:=ZeroVec;
      for sy := 0 to 1 do begin
        for sx := 0 to 1 do begin
          for s := 0 to samps - 1 do begin
            r1 := 2 * random;
            if (r1 < 1) then
              dx := sqrt(r1) - 1
            else
              dx := 1 - sqrt(2 - r1);

            r2 := 2 * random;
            if (r2 < 1) then
              dy := sqrt(r2) - 1
            else
              dy := 1 - sqrt(2 - r2);

            d:= cx* (((sx + 0.5 + dx) / 2 + x) / w - 0.5)
               +cy* (((sy + 0.5 + dy) / 2 + (h - y - 1)) / h - 0.5);
            d:= (d +cam.d).norm;

   
   //         tempRay.o:= d* 140+cam.o;
            tempRay.d := d;
            tempRay.o := d*cam.PlaneDist+cam.p;
            temp:=HybridBVH.Radiance(tempRay, 0);
            temp:= temp/ samps;
            r:= r+temp;
          end;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=ZeroVec;
        end;(*sx*)
      end;(*sy*)
      vColor:=ColToRGB(tColor);
      BMP.SetPixel(x,h-y-1,vColor);
    end;(* for x *)
  end;(*for y*)
  writeln ('The time is : ',TimeToStr(Time));
  if UpperCase(ExtractFileExt(FN))='.BMP' then  BMP.WriteBMPFile(FN) else BMP.WritePPM(FN);
end.
