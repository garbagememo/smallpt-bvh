unit uScene;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}
interface
uses Math,uVect,Classes;


const 
  eps=1e-4;
  INF=1e20;
type

   AABBRecord=Record
      Min,Max:Vec3;
      function hit(r:RayRecord;tmin,tmax:real):boolean;
      function new(m0,m1:Vec3):AABBRecord;
   end;

   SphereClass=class
    rad:real;       //radius
    p,e,c:Vec3;// position. emission,color
    refl:RefType;
    BoundBox:AABBRecord;
    constructor Create(rad_:real;p_,e_,c_:Vec3;refl_:RefType);
    function intersect(const r:RayRecord):real;
   end;
   
   CamRecord=record
      p,d:Vec3;
      PlaneDist:real;
   end;
   
function MargeBoundBox(box0,box1:AABBRecord):AABBRecord;
function InitScene:CamRecord;
function RandomScene:CamRecord;
function testScene:CamRecord;
function testScene2:CamRecord;
function intersect(const r:RayRecord):InterRecord;
var
  sph:TList;

implementation
function MargeBoundBox(box0,box1:AABBRecord):AABBRecord;
var
   small,big:Vec3;
begin
  small.new(min(box0.min.x, box1.min.x),
            min(box0.min.y, box1.min.y),
            min(box0.min.z, box1.min.z));

  big.new(max(box0.max.x, box1.max.x),
          max(box0.max.y, box1.max.y),
          max(box0.max.z, box1.max.z) );

  result.new(small,big);

end;


function AABBRecord.new(m0,m1:Vec3):AABBRecord;
begin
   min:=m0;max:=m1;
   result:=self;
end;

function AABBRecord.hit(r:RayRecord;tmin,tmax:real):boolean;
var
  invD,t0,t1,tswap:real;
begin
   //tminがマイナスの場合を除外するため、tmin=EPS,tmax=INFとしている。引数意味なくない？
   invD := 1.0 / r.d.x;
   t0 := (Min.x - r.o.x) * invD;
    t1 := (max.x - r.o.x) * invD;
    if (invD < 0.0) then begin tswap:=t1;t1:=t0;t0:=tswap end;

    if t0>tmin then tmin:=t0;
    if t1<tmax then tmax:=t1;
    if (tmax <= tmin) then exit(false);

    invD := 1.0 / r.d.y;
    t0 := (Min.y - r.o.y) * invD;
    t1 := (max.y - r.o.y) * invD;
    if (invD < 0.0) then begin tswap:=t1;t1:=t0;t0:=tswap end;

    if t0>tmin then tmin:=t0;
    if t1<tmax then tmax:=t1;
    if (tmax <= tmin) then exit(false);

    invD := 1.0 / r.d.z;
    t0 := (Min.z - r.o.z) * invD;
    t1 := (max.z - r.o.z) * invD;
    if (invD < 0.0) then begin tswap:=t1;t1:=t0;t0:=tswap end;

    if t0>tmin then tmin:=t0;
    if t1<tmax then tmax:=t1;
    if (tmax <= tmin) then exit(false);

    result:=true;
end;

constructor SphereClass.Create(rad_:real;p_,e_,c_:Vec3;refl_:RefType);
var
  b:Vec3;
begin
   rad:=rad_;p:=p_;e:=e_;c:=c_;refl:=refl_;
   BoundBox.new(p - b.new(rad, rad, rad),
                p + b.new(rad, rad, rad));

end;

function SphereClass.intersect(const r:RayRecord):real;
var
  op:Vec3;
  t,b,det:real;
begin
  op:=p-r.o;
  t:=eps;b:=op*r.d;det:=b*b-op*op+rad*rad;
  if det<0 then 
    result:=INF
  else begin
    det:=sqrt(det);
    t:=b-det;
    if t>eps then 
      result:=t
    else begin
      t:=b+det;
      if t>eps then 
        result:=t
      else
        result:=INF;
    end;
  end;
end;

function InitScene:CamRecord;
var
  p,c,e:Vec3;
  vp,vc,vd:Vec3;
begin
  sph:=TList.Create;
  sph.add( SphereClass.Create(1e5, p.new( 1e5+1,40.8,81.6),  ZeroVec,            c.new(0.75,0.25,0.25),DIFF) );//Left
  sph.add( SphereClass.Create(1e5, p.new(-1e5+99,40.8,81.6), ZeroVec,            c.new(0.25,0.25,0.75),DIFF) );//Right
  sph.add( SphereClass.Create(1e5, p.new(50,40.8, 1e5),      ZeroVec,            c.new(0.75,0.75,0.75),DIFF) );//Back
  sph.add( SphereClass.Create(1e5, p.new(50,40.8,-1e5+170),  ZeroVec,            c.new(0,0,0),         DIFF) );//Front
  sph.add( SphereClass.Create(1e5, p.new(50, 1e5, 81.6),     ZeroVec,            c.new(0.75,0.75,0.75),DIFF) );//Bottomm
  sph.add( SphereClass.Create(1e5, p.new(50,-1e5+81.6,81.6), ZeroVec,            c.new(0.75,0.75,0.75),DIFF) );//Top
  sph.add( SphereClass.Create(16.5,p.new(27,16.5,47),        ZeroVec,            c.new(1,1,1)*0.999,   SPEC) );//Mirror
  sph.add( SphereClass.Create(16.5,p.new(73,16.5,88),        ZeroVec,            c.new(1,1,1)*0.999,   REFR) );//Glass
  sph.add( SphereClass.Create(600, p.new(50,681.6-0.27,81.6),e.new(12,12,12),    ZeroVec,              DIFF) );//Ligth

  result.p:=vp.new(50, 52, 295.6);
  result.d:=vd.new(0, -0.042612, -1.0).norm;
  result.PlaneDist:=170;
end;

function RandomScene:CamRecord;
var
   Cen,Cen1,Cen2,Cen3:Vec3;
   a,b:integer;
   RandomMatterial:real;
   p,c,e:Vec3;
   vp,vc,vd:Vec3;
begin
  sph:=TList.Create;
  Cen.new(50,40.8,-860);

  Cen1.new(75,25, 85);
  Cen2.new(45,25, 30);
  Cen3.new(15,25,-25);
  

  sph.add(SphereClass.Create(10000,  Cen+p.new(0,0,-200)  , e.new(0.6, 0.5, 0.7)*0.8, c.new(0.7,0.9,1.0),  DIFF)); // sky
  sph.add(SphereClass.Create(100000, p.new(50, -100000, 0), ZeroVec,                  c.new(0.4,0.4,0.4),  DIFF)); // grnd


  sph.add(SphereClass.Create(25,  Cen1 ,ZeroVec,c.new(0.9,0.9,0.9), SPEC));// Glas
  sph.add(SphereClass.Create(25,  Cen2 ,ZeroVec,c.new(0.95,0.95,0.95),  REFR)); // Glass
  sph.add(SphereClass.Create(25,  Cen3 ,ZeroVec,c.new(1,0.6,0.6)*0.696, DIFF));    // 乱反射
  for a:=-11 to 11 do begin
     for b:=-11 to 11 do begin
        RandomMatterial:=random;
        Cen.new( (a+random)*25,5,(b+random)*25);
        if ( (Cen - Cen1) ).len>25*0.9 then begin
           if RandomMatterial<0.8 then begin
              sph.add(SphereClass.Create(5,Cen,ZeroVec,c.new(random,Random,random),DIFF));
           end
           else if RandomMatterial <0.95 then begin
              sph.add(SphereClass.Create(5,Cen,ZeroVec,c.new(random,Random,random),SPEC));
           end
           else begin
              sph.add(SphereClass.Create(5,Cen,ZeroVec,c.new(random,Random,random),REFR));
           end;
        end;
     end;
  end;
  result.p:=vp.new(55, 58, 245.6);
  result.d:=vd.new(0, -0.24, -1.0).norm;
  result.PlaneDist:=70;  
end;


function testScene:CamRecord;
var
   Cen,Cen1,Cen2,Cen3:Vec3;
   a,b:integer;
   RandomMatterial:real;
   p,c,e:Vec3;
   vp,vc,vd:Vec3;
begin
  sph:=TList.Create;
  Cen.new(50,40.8,-860);

  Cen1.new(75,25, 85);
  Cen2.new(45,25, 30);
  Cen3.new(15,25,-25);
  

  sph.add(SphereClass.Create(10000,  Cen+p.new(0,0,-200)  , e.new(0.6, 0.5, 0.7)*0.8, c.new(0.7,0.9,1.0),  DIFF)); // sky
  sph.add(SphereClass.Create(100000, p.new(50, -100000, 0), ZeroVec,                  c.new(0.4,0.4,0.4),  DIFF)); // grnd


  sph.add(SphereClass.Create(25,  Cen1 ,ZeroVec,c.new(0.9,0.9,0.9), SPEC));// Glas
  sph.add(SphereClass.Create(25,  Cen2 ,ZeroVec,c.new(0.95,0.95,0.95),  REFR)); // Glass
  sph.add(SphereClass.Create(25,  Cen3 ,ZeroVec,c.new(1,0.6,0.6)*0.696, DIFF));    // 乱反射

  result.p:=vp.new(55, 58, 245.6);
  result.d:=vd.new(0, -0.24, -1.0).norm;
  result.PlaneDist:=70;  
end;


function testScene2:CamRecord;
var
   Cen,Cen1,Cen2,Cen3:Vec3;
   a,b:integer;
   RandomMatterial:real;
   p,c,e:Vec3;
   vp,vc,vd:Vec3;
begin
  sph:=TList.Create;
  Cen.new(50,40.8,-860);

  Cen1.new(75,25, 85);
  Cen2.new(45,25, 30);
  Cen3.new(15,25,-25);
  

  sph.add(SphereClass.Create(10000,  Cen+p.new(0,0,-200)  , e.new(0.6, 0.5, 0.7)*0.8, c.new(0.7,0.9,1.0),  DIFF)); // sky
  sph.add(SphereClass.Create(100000, p.new(50, -100000, 0), ZeroVec,                  c.new(0.4,0.4,0.4),  DIFF)); // grnd


  sph.add(SphereClass.Create(25,  Cen2 ,ZeroVec,c.new(0.95,0.95,0.95),  REFR)); // Glass


  result.p:=vp.new(55, 58, 245.6);
  result.d:=vd.new(0, -0.24, -1.0).norm;
  result.PlaneDist:=70;  
end;


function intersect(const r:RayRecord):InterRecord;
var 
  n,d:real;
  i:integer;
begin
  result.t:=INF;
  for i:=0 to sph.count-1 do begin
    d:=SphereClass(sph[i]).intersect(r);
    if d<result.t then begin
      result.t:=d;
      result.id:=i;
    end;
  end;
  result.isHit:=(result.t<inf);
end;

begin
end.
   
