program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

uses SysUtils,Classes,Math,uVect,uScene,uBMP,uBVH,getopts;

var
  BVH:BVHNode;

function radiance(const r:RayRecord;depth:integer):Vec3;
var
  id:integer;
  obj:SphereClass;
  x,n,f,nl,u,v,w,d:Vec3;
  p,r1,r2,r2s,t:real;
  into:boolean;
  ray2,RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:Vec3;
  ir:InterRecord;
begin
  ir.id:=0;depth:=depth+1;
  ir:=BVH.intersection(r);
  if ir.isHit=false then begin
    result:=ZeroVec;exit;
  end;
  obj:=SphereClass(sph[ir.id]);
  x:=r.o+r.d*ir.t; n:=(x-obj.p).norm; f:=obj.c;
  if n.dot(r.d)<0 then nl:=n else nl:=n*-1;
  if (f.x>f.y)and(f.x>f.z) then
    p:=f.x
  else if f.y>f.z then 
    p:=f.y
  else
    p:=f.z;
   if (depth>5) then begin
    if random<p then 
      f:=f/p 
    else begin
      result:=obj.e;
      exit;
    end;
  end;
  case obj.refl of
    DIFF:begin
      r1:=2*PI*random;r2:=random;r2s:=sqrt(r2);
      w:=nl;
      if abs(w.x)>0.1 then
        u:=(u.new(0,1,0)/w).norm 
      else begin
        u:=(u.new(1,0,0)/w ).norm;
      end;
      v:=w/u;
      d := (u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2)).norm;
      result:=obj.e+f.Mult(radiance(ray2.new(x,d),depth) );
    end;(*DIFF*)
    SPEC:begin
      result:=obj.e+f.Mult((radiance(ray2.new(x,r.d-n*2*(n*r.d) ),depth)));
    end;(*SPEC*)
    REFR:begin
      RefRay.new(x,r.d-n*2*(n*r.d) );
      into:= (n*nl>0);
      nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl; 
      cos2t:=1-nnt*nnt*(1-ddn*ddn);
      if cos2t<0 then begin   // Total internal reflection
        result:=obj.e + f.Mult(radiance(RefRay,depth));
        exit;
      end;
      if into then q:=1 else q:=-1;
      tdir := (r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t)))).norm;
      if into then Q:=-ddn else Q:=tdir*n;
      a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
      Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
      if depth>2 then begin
        if random<p then // 反射
          result:=obj.e+f.Mult(radiance(RefRay,depth)*RP)
        else //屈折
          result:=obj.e+f.Mult(radiance(ray2.new(x,tdir),depth)*TP);
      end
      else begin// 屈折と反射の両方を追跡
        result:=obj.e+f.Mult(radiance(RefRay,depth)*Re+radiance(ray2.new(x,tdir),depth)*Tr);
      end;
    end;(*REFR*)
  end;(*CASE*)
end;


var
  x,y,sx,sy,i,s: integer;
  w,h,samps,height    : integer;
  temp,d       : Vec3;
  r1,r2,dx,dy  : real;
  tempRay  : RayRecord;
  cam:CamRecord;
  cx,cy: Vec3;
  tColor,r,camPosition,camDirection : Vec3;

  BMP:BMPRecord;
  ScrWidth,ScrHeight:integer;
  vColor:rgbColor;
  ArgInt:integer;
  FN,ArgFN:string;
  c:char;
  a:IntegerArray;
  //debug
  sp:SphereClass;
begin
  FN:='temp.bmp';
  w:=1024 ;h:=768;  samps := 16;
  c:=#0;
  repeat
    c:=getopt('o:s:w:');

    case c of
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
         writeln(' -o [finename] output filename');
         writeln(' -s [samps] sampling count');
         writeln(' -w [width] screen width pixel');
      end;
    end; { case }
  until c=endofoptions;
  height:=h;
  BMP.new(w,h);
  writeln('BMP=OK');
  //  InitScene;
  Randomize;
  cam:=RandomScene;
 
  
  SetLength(a,sph.count);
  for i:=0 to sph.count-1 do a[i]:=i;
  BVH:=BVHNode.Create(a,sph);

  cx.new(w * 0.5135 / h, 0, 0);
  cy:= (cx/ cam.d).norm;
  cy:= cy* 0.5135;

  ScrWidth:=0;
  ScrHeight:=0;
  writeln ('The time is : ',TimeToStr(Time));
(*
  cam.p:=vp.new(55, 58, 245.6);
  cam.d:=vd.new(0, -0.24, -1.0).norm;
  cam.PlaneDist:=70;  
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
            temp:=Radiance(tempRay, 0);
            temp:= temp/ samps;
            r:= r+temp;
          end;(*samps*)
          temp:= ClampVector(r)* 0.25;
          tColor:=tColor+ temp;
          r:=ZeroVec;
        end;(*sx*)
      end;(*sy*)
      vColor:=ColToRGB(tColor);
      BMP.SetPixel(x,height-y,vColor);
    end;(* for x *)
  end;(*for y*)
  writeln ('The time is : ',TimeToStr(Time));
  BMP.WritePPM('test.ppm');
end.
