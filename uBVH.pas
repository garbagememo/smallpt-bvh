unit uBVH;
{$MODE objfpc}{$H+}
{$INLINE ON}
{$modeswitch advancedrecords}

interface
uses uVect,uScene,Math,Classes;
const
  Nil_Leaf=16384;
type
  IntegerArray=array of integer;

  BVHNode=Class
    root:AABBRecord;
    left,right:BVHNode;
    leaf:integer;
    constructor Create(ary:IntegerArray;sph:TList);
    function intersection(r:RayRecord):InterRecord;
  end;

procedure AABBSort(var a: array of integer;axis:integer);
   
   
   
implementation


function GetVal(suf:integer;axis:integer):real;
begin
  case axis of
    1:result:=SphereClass(sph[suf]).BoundBox.min.x;
    2:result:=SphereClass(sph[suf]).BoundBox.min.y;
    else begin
      result:=SphereClass(sph[suf]).BoundBox.min.z;
    end;
  end ;(*case*)
end;
procedure AABBSort(var a: array of integer;axis:integer);
var
   i, j, h, n,v: integer;
   v1,v2:real;
begin
  n := length(a);
  h := 1;
  repeat
    h := 3*h + 1
  until h > n;
  repeat
    h := h div 3;
    for i := h to n-1 do begin
      v := a[i];
      j := i;
      while (j >= h) AND (GetVal(a[j-h],axis) > GetVal(a[i],axis)) do begin
        a[j] := a[j-h];
        j := j - h;
      end;
      a[j] := v;
    end;(*for*)
   until h = 1;
end;

constructor BVHnode.Create(ary:IntegerArray;sph:TList);
var
   upAry,DownAry:IntegerArray;
   axis,i,len:integer;
   ar:real;
begin
   (*//debug
   for i:=0 to High(ary) do begin
      write('ary[',i,']=',ary[i]);
   end;
   writeln;
   //debug*)
   root:=sphereclass(sph[ary[0]]).BoundBox;
   Leaf:=Nil_Leaf;
   ar:=random;
   if ar>0.67 then axis:=1 else if ar>0.33 then axis:=2 else axis:=3;

  case High(Ary) of
    0:Leaf:=ary[0];//要素1
    1:begin
       Root:=MargeBoundBox(Root,SphereClass(sph[ary[1] ]).BoundBox);
       setLength(UpAry,1);SetLength(downAry,1);
       upAry[0]:=Ary[0];DownAry[0]:=Ary[1];
       Left:=BVHNode.Create(upAry,sph);
       right:=BVHNode.Create(DownAry,sph);
    end;
    else begin
      AABBSort(ary,axis);
      for i:=1 to high(ary)  do begin
        Root:=MargeBoundBox(Root,SphereClass(sph[ary[i] ]).BoundBox);
      end;
      len:=length(Ary) div 2;
      upAry:=Copy(Ary,0,len);
      DownAry:=Copy(Ary,len,length(Ary)-len);
       
      Left:=BVHNode.Create(UpAry,sph);
      right:=BVHNode.Create(DownAry,sph);
    end;
  end;
end;

function BVHnode.intersection(r:RayRecord):InterRecord;
var
   RIR,LIR:InterRecord;
   t:real;
begin
  result.isHit:=false;
  result.t:=INF;
  result.id:=0;
  if leaf<>Nil_Leaf then begin
     result.t:=SphereClass(sph[leaf]).intersect(r);
     if result.t<INF then begin
        result.id:=Leaf;
        result.isHit:=true;
     end;
     exit;
  end;
  
  if root.Hit(r,EPS,INF) then begin
     RIR:=Right.intersection(r);
     LIR:=Left.intersection(r);
     if (LIR.isHit or RIR.isHit) then begin
        if RIR.isHit then result:=RIR;
        if LIR.isHit then begin
           if RIR.isHit=false then
              result:=LIR
           else if RIR.t>LIR.t then
              result:=LIR;
        end;
     end;
  end
  else begin
    result.isHit:=false;
    result.t:=INF;
  end;
end;

end.
