program smallpt;
{$MODE objfpc}{$H+}
{$INLINE ON}

uses SysUtils,Classes,Math,uVect,uScene,uBMP,uBVH,getopts;

const 
  eps=1e-4;
  INF=1e20;
  M_2PI=PI*2;
  M_1_PI=1/PI;

var
  BVH:BVHNodeClass;
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
  ir:=BVH.intersect(r);
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


function radiance_ne_rev(r:RayRecord;depth:integer;E:integer):Vec3;
var
  i,tid:integer;
  obj,s:SphereClass;
  x,n,f,nl,u,v,w,d:Vec3;
  p,r1,r2,r2s,ss,cc:real;
  into:boolean;
  Ray2,RefRay:RayRecord;
  nc,nt,nnt,ddn,cos2t,q,a,b,c,R0,Re,RP,Tr,TP:real;
  tDir:Vec3;
  EL,sw,su,sv,l:Vec3;
  cos_a_max,eps1,eps2,eps2s,cos_a,sin_a,phi,omega:real;
  cl,cf:Vec3;
  tir,ir:InterRecord;
begin
   ir.id:=0;depth:=depth+1;
   ir:=BVH.intersect(r);
  if ir.isHit=FALSE then begin
    result:=ZeroVec;exit;
  end;
  obj:=SphereClass(sph[ir.id]);
  x:=r.o+r.d*ir.t; n:=(x-obj.p).norm; f:=obj.c;
  IF n.dot(r.d)<0 THEN nl:=n else nl:=n*-1;
  IF (f.x>f.y)and(f.x>f.z) THEN
    p:=f.x
  ELSE IF f.y>f.z THEN 
    p:=f.y
  ELSE
    p:=f.z;
   if (depth>5) then begin
    if random<p then 
      f:=f/p 
    else begin
      result:=obj.e;
      exit;
    end;
  end;
  CASE obj.refl OF
    DIFF:BEGIN
      r1:=2*PI*random;r2:=random;r2s:=sqrt(r2);
      w:=nl;
      IF abs(w.x)>0.1 THEN
        u:=(u.new(0,1,0)/w).norm 
      ELSE BEGIN
        u:=(u.new(1,0,0)/w ).norm;
      END;
      v:=w/u;
      d := (u*cos(r1)*r2s + v*sin(r1)*r2s + w*sqrt(1-r2)).norm;
        // Loop over any lights
        EL:=ZeroVec;
        tid:=ir.id;
        for i:=0 to sph.count-1 do begin
          s:=SphereClass(sph[i]);
          if (i=tid) then begin
            continue;
          end;
          if (s.e.x<=0) and  (s.e.y<=0) and (s.e.z<=0)  then continue; // skip non-lights
          sw:=s.p-x;
          tr:=sw*sw;  tr:=s.rad*s.rad/tr;
          if abs(sw.x)/sqrt(tr)>0.1 then 
            su:=(su.new(0,1,0)/sw).norm 
          else 
            su:=(su.new(1,0,0)/sw).norm;
          sv:=sw/su;
          if tr>1 then begin
            (*半球の内外=cos_aがマイナスとsin_aが＋、－で場合分け*)
            (*半球内部なら乱反射した寄与全てを取ればよい・・はず*)
            eps1:=M_2PI*random;eps2:=random;eps2s:=sqrt(eps2);
            sincos(eps1,ss,cc);
            l:=(u*(cc*eps2s)+v*(ss*eps2s)+w*sqrt(1-eps2)).norm;
            tir:=BVH.intersect(Ray2.new(x,l));
             if tir.isHit then begin
                if tir.id=i then begin
                   tr:=l*nl;
                   EL:=EL+f.mult(s.e)*tr;
                end;
             end;
          end
          else begin //半球外部の場合;
            cos_a_max := sqrt(1-tr );
            eps1 := random; eps2:=random;
            cos_a := 1-eps1+eps1*cos_a_max;
            sin_a := sqrt(1-cos_a*cos_a);
            if (1-2*random)<0 then sin_a:=-sin_a; 
            phi := M_2PI*eps2;
            l:=(sw*(cos(phi)*sin_a)+sv*(sin(phi)*sin_a)+sw*cos_a).norm;
            tir:=BVH.intersect(Ray2.new(x,l));
            if tir.isHit then begin 
              if tir.id=i then begin  // shadow ray
                omega := 2*PI*(1-cos_a_max);
                tr:=l*nl;
                if tr<0 then tr:=0;
                EL:=EL+f.mult(s.e*tr*omega)*M_1_PI;// 1/pi for brdf
              end;
            end;
          end;
        end;(*for*)
      result:=obj.e*E+EL+f.Mult(radiance_ne_rev(ray2.new(x,d),depth,0) );
    END;(*DIFF*)
    SPEC:BEGIN
      result:=obj.e+f.mult(radiance_ne_rev(ray2.new(x,r.d-n*2*(n*r.d) ),depth,1));
    END;(*SPEC*)
    REFR:BEGIN
      RefRay.new(x,r.d-n*2*(n*r.d) );
      into:= (n*nl>0);
      nc:=1;nt:=1.5; if into then nnt:=nc/nt else nnt:=nt/nc; ddn:=r.d*nl; 
      cos2t:=1-nnt*nnt*(1-ddn*ddn);
      if cos2t<0 then begin   // Total internal reflection
        result:=obj.e + f.mult(radiance_ne_rev(RefRay,depth,1));
        exit;
      end;
      if into then q:=1 else q:=-1;
      tdir := (r.d*nnt - n*(q*(ddn*nnt+sqrt(cos2t)))).norm;
      IF into then Q:=-ddn else Q:=tdir*n;
      a:=nt-nc; b:=nt+nc; R0:=a*a/(b*b); c := 1-Q;
      Re:=R0+(1-R0)*c*c*c*c*c;Tr:=1-Re;P:=0.25+0.5*Re;RP:=Re/P;TP:=Tr/(1-P);
      IF depth>2 THEN BEGIN
        IF random<p then // 反射
          result:=obj.e+f.mult(radiance_ne_rev(RefRay,depth,1)*RP)
        ELSE //屈折
          result:=obj.e+f.mult(radiance_ne_rev(ray2.new(x,tdir),depth,1)*TP);
      END
      ELSE BEGIN// 屈折と反射の両方を追跡
        result:=obj.e+f.mult(radiance_ne_rev(RefRay,depth,1)*Re+radiance_ne_rev(ray2.new(x,tdir),depth,1)*Tr);
      END;
    END;(*REFR*)
  END;(*CASE*)
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
  FN:='temp.ppm';
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

  Randomize;
  cam:=wadaScene;

  writeln('Set Scene'); 
  writeln('Sample=',samps);
  SetLength(a,sph.count);
  for i:=0 to sph.count-1 do a[i]:=i;
  BVH:=BVHNodeClass.Create(a,sph);

  cx.new(w * 0.5135 / h, 0, 0);
  cy:= (cx/ cam.d).norm;
  cy:= cy* 0.5135;

  ScrWidth:=0;
  ScrHeight:=0;
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
            temp:=Radiance_ne_rev(tempRay, 0,1);
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
  BMP.WritePPM(FN);
end.
