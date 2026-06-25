unit udCollections.Lists;

interface

uses
  System.SysUtils;

type
  EDCollectionsError = class(Exception);
  EDCollectionsArgumentOutOfRange = class(EDCollectionsError);

  TDListNotification = (lnAdded, lnRemoved, lnExtracted, lnDeleted, lnCleared);

  TDCustomListBase = class abstract
  private
    FCount: Integer;
    FCapacity: Integer;
    procedure SetCapacity(const AValue: Integer);
  protected
    procedure CheckIndex(const AIndex: Integer); inline;
    procedure CheckInsertIndex(const AIndex: Integer); inline;
    procedure DoSetCapacity(const AValue: Integer); virtual;
    procedure Grow;
    procedure SetCount(const AValue: Integer); inline;
    property CountInternal: Integer read FCount write SetCount;
  public
    constructor Create; virtual;
    procedure Clear; virtual; abstract;
    procedure TrimExcess; virtual;
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity write SetCapacity;
  end;

  TDObjectListBase = class;

  TDObjectListBaseEnumerator = class
  private
    FList: TDObjectListBase;
    FIndex: Integer;
    function GetCurrent: TObject; inline;
  public
    constructor Create(const AList: TDObjectListBase);
    function MoveNext: Boolean; inline;
    property Current: TObject read GetCurrent;
  end;

  TDObjectBasePredicate = reference to function(const AItem: TObject): Boolean;
  TDObjectBaseProc = reference to procedure(const AItem: TObject);
  TDObjectMatchCallback = function(const AItem: TObject; const AContext: Pointer): Boolean;

  {TDObjectListBase encapsulates the algorithms that traverse or move items.
    TDObjectList<T> serves as a facade to reduce the amount of code. }
  TDObjectListBase = class(TDCustomListBase)
  private
    FItems: array of TObject;
    FOwnsObjects: Boolean;
    function GetItem(const AIndex: Integer): TObject; inline;
    procedure SetItem(const AIndex: Integer; const AValue: TObject);
    procedure DeleteAtChecked(const AIndex: Integer; const AAction: TDListNotification);
    procedure FinalizeItem(const AItem: TObject; const AAction: TDListNotification); inline;
  protected
    procedure DoSetCapacity(const AValue: Integer); override;
    procedure InternalAddRange(const AItems; const ACount: Integer);
    function InternalFirst: TObject; inline;
    function InternalLast: TObject; inline;
    function InternalAny(const ACallback: TDObjectMatchCallback; const AContext: Pointer): Boolean;
    function InternalCountIf(const ACallback: TDObjectMatchCallback; const AContext: Pointer): Integer;
    function InternalFindIndex(const ACallback: TDObjectMatchCallback; const AContext: Pointer): Integer;inline;
    function InternalFindLastIndex(const ACallback: TDObjectMatchCallback; const AContext: Pointer): Integer;
    function InternalRemoveWhere(const ACallback: TDObjectMatchCallback; const AContext: Pointer): Integer;
    procedure Notify(const AItem: TObject; const AAction: TDListNotification); virtual;
  public
    constructor Create(const AOwnsObjects: Boolean = True); reintroduce; virtual;
    destructor Destroy; override;

    function Add(const AItem: TObject): Integer; virtual;
    procedure AddRange(const AItems: array of TObject); virtual;
    procedure Insert(const AIndex: Integer; const AItem: TObject); virtual;
    procedure Delete(const AIndex: Integer); virtual;
    function Extract(const AItem: TObject): TObject; virtual;
    function ExtractAt(const AIndex: Integer): TObject; virtual;
    function Remove(const AItem: TObject): Integer; virtual;
    function RemoveWhere(const APredicate: TDObjectBasePredicate): Integer; virtual;
    procedure Clear; override;

    procedure Exchange(const AIndex1, AIndex2: Integer); virtual;
    procedure Move(const ACurIndex, ANewIndex: Integer); virtual;
    function IndexOf(const AItem: TObject): Integer; virtual;
    function Contains(const AItem: TObject): Boolean; inline;
    function First: TObject; inline;
    function Last: TObject; inline;
    function Any(const APredicate: TDObjectBasePredicate): Boolean; virtual;
    function CountIf(const APredicate: TDObjectBasePredicate): Integer; virtual;
    function FindIndex(const APredicate: TDObjectBasePredicate): Integer; virtual;
    function FindLastIndex(const APredicate: TDObjectBasePredicate): Integer; virtual;

    function GetEnumerator: TDObjectListBaseEnumerator;
    property Items[const AIndex: Integer]: TObject read GetItem write SetItem; default;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;

  { These callbacks preserve the typed API. The generic implementation merely
    adapts T to TObject and delegates the loops to TDObjectListBase. These
    adapters remain in TDObjectList<T> because the public API accepts
    TDObjectPredicate<T>/TDObjectProc<T>;}
  TDObjectPredicate<T: class> = reference to function(const AItem: T): Boolean;
  TDObjectProc<T: class> = reference to procedure(const AItem: T);

  TDObjectListEnumerator<T: class> = class
  private
    FList: TDObjectListBase;
    FIndex: Integer;
    function GetCurrent: T; inline;
  public
    constructor Create(const AList: TDObjectListBase);
    function MoveNext: Boolean; inline;
    property Current: T read GetCurrent;
  end;

  { The code that remains in `TDObjectList<T>` exists solely to preserve the typed contract: `T` return values, the `Items: T` property, 
  `for..in` iteration over `T`, open arrays of `T`, and `TDObjectPredicate<T>`/`TDObjectProc<T>` callbacks. 
  The typed parameter wrappers are retained for source compatibility and delegate to the base implementation in a single line; 
  the loops and data movement logic remain non-generic.
 }
  TDObjectList<T: class> = class(TDObjectListBase)
  private
    function GetTypedItem(const AIndex: Integer): T; inline;
    procedure SetTypedItem(const AIndex: Integer; const AValue: T); inline;
  public
    function Add(const AItem: T): Integer; reintroduce; inline;
    procedure AddRange(const AItems: array of T); reintroduce;
    procedure Insert(const AIndex: Integer; const AItem: T); reintroduce; inline;
    function Extract(const AItem: T): T; reintroduce; inline;
    function ExtractAt(const AIndex: Integer): T; reintroduce; inline;
    function Remove(const AItem: T): Integer; reintroduce; inline;
    function RemoveWhere(const APredicate: TDObjectPredicate<T>): Integer; reintroduce;
    function IndexOf(const AItem: T): Integer; reintroduce; inline;
    function Contains(const AItem: T): Boolean; reintroduce; inline;
    function First: T; reintroduce; inline;
    function Last: T; reintroduce; inline;
    function Any(const APredicate: TDObjectPredicate<T>): Boolean; reintroduce;
    function CountIf(const APredicate: TDObjectPredicate<T>): Integer; reintroduce;
    function FindIndex(const APredicate: TDObjectPredicate<T>): Integer; reintroduce;
    function FindLastIndex(const APredicate: TDObjectPredicate<T>): Integer; reintroduce;
    function GetEnumerator: TDObjectListEnumerator<T>; reintroduce; inline;
    property Items[const AIndex: Integer]: T read GetTypedItem write SetTypedItem; default;
  end;

implementation

const
  CDefaultCapacity = 4;

type
  PObjectBasePredicate = ^TDObjectBasePredicate;
  PObjectBaseProc = ^TDObjectBaseProc;

function InvokeBasePredicate(
  const AItem: TObject;
  const AContext: Pointer): Boolean;
begin
  Result := PObjectBasePredicate(AContext)^(AItem);
end;

procedure InvokeBaseProc(
  const AItem: TObject;
  const AContext: Pointer);
begin
  PObjectBaseProc(AContext)^(AItem);
end;

{ TDCustomListBase }

constructor TDCustomListBase.Create;
begin
  inherited Create;
end;

procedure TDCustomListBase.CheckIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EDCollectionsArgumentOutOfRange.CreateFmt('Index out of range (%d).', [AIndex]);
end;

procedure TDCustomListBase.CheckInsertIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > FCount) then
    raise EDCollectionsArgumentOutOfRange.CreateFmt('Insert index out of range (%d).', [AIndex]);
end;

procedure TDCustomListBase.DoSetCapacity(const AValue: Integer);
begin
  FCapacity := AValue;
end;

procedure TDCustomListBase.Grow;
var
  LNewCapacity: Integer;
begin
  if FCapacity > 64 then
    LNewCapacity := FCapacity + (FCapacity div 4)
  else if FCapacity > 0 then
    LNewCapacity := FCapacity * 2
  else
    LNewCapacity := CDefaultCapacity;

  Capacity := LNewCapacity;
end;

procedure TDCustomListBase.SetCapacity(const AValue: Integer);
begin
  if AValue < FCount then
    raise EDCollectionsArgumentOutOfRange.CreateFmt(
      'Capacity (%d) cannot be smaller than Count (%d).',
      [AValue, FCount]
    );

  if AValue <> FCapacity then
    DoSetCapacity(AValue);
end;

procedure TDCustomListBase.SetCount(const AValue: Integer);
begin
  FCount := AValue;
end;

procedure TDCustomListBase.TrimExcess;
begin
  Capacity := Count;
end;

{ TDObjectListBaseEnumerator }

constructor TDObjectListBaseEnumerator.Create(const AList: TDObjectListBase);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TDObjectListBaseEnumerator.GetCurrent: TObject;
begin
  Result := FList[FIndex];
end;

function TDObjectListBaseEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FList.Count - 1;
  if Result then
    Inc(FIndex);
end;

{ TDObjectListBase }

constructor TDObjectListBase.Create(const AOwnsObjects: Boolean);
begin
  inherited Create;
  FOwnsObjects := AOwnsObjects;
end;

destructor TDObjectListBase.Destroy;
begin
  Clear;
  inherited;
end;

function TDObjectListBase.Add(const AItem: TObject): Integer;
begin
  Result := Count;
  Insert(Result, AItem);
end;

procedure TDObjectListBase.AddRange(const AItems: array of TObject);
begin
  if Length(AItems) > 0 then
    InternalAddRange(AItems[0], Length(AItems));
end;

function TDObjectListBase.Any(const APredicate: TDObjectBasePredicate): Boolean;
begin
  if not Assigned(APredicate) then
    Exit(False);

  Result := InternalAny(InvokeBasePredicate, @APredicate);
end;

procedure TDObjectListBase.Clear;
var
  I: Integer;
  LItem: TObject;
begin
  for I := Count - 1 downto 0 do
  begin
    LItem := FItems[I];
    FItems[I] := nil;
    FinalizeItem(LItem, lnCleared);
  end;

  CountInternal := 0;
end;

function TDObjectListBase.Contains(const AItem: TObject): Boolean;
begin
  Result := IndexOf(AItem) >= 0;
end;

function TDObjectListBase.CountIf(const APredicate: TDObjectBasePredicate): Integer;
begin
  if not Assigned(APredicate) then
    Exit(0);

  Result := InternalCountIf(InvokeBasePredicate, @APredicate);
end;

procedure TDObjectListBase.Delete(const AIndex: Integer);
begin
  CheckIndex(AIndex);
  DeleteAtChecked(AIndex, lnDeleted);
end;

procedure TDObjectListBase.DeleteAtChecked(
  const AIndex: Integer;
  const AAction: TDListNotification);
var
  LItem: TObject;
  LMoveCount: Integer;
begin
  LItem := FItems[AIndex];
  LMoveCount := Count - AIndex - 1;

  if LMoveCount > 0 then
    System.Move(FItems[AIndex + 1], FItems[AIndex], LMoveCount * SizeOf(Pointer));

  FItems[Count - 1] := nil;
  CountInternal := Count - 1;
  FinalizeItem(LItem, AAction);
end;

procedure TDObjectListBase.DoSetCapacity(const AValue: Integer);
begin
  SetLength(FItems, AValue);
  inherited DoSetCapacity(AValue);
end;

procedure TDObjectListBase.Exchange(const AIndex1, AIndex2: Integer);
var
  LTemp: TObject;
begin
  CheckIndex(AIndex1);
  CheckIndex(AIndex2);

  if AIndex1 = AIndex2 then
    Exit;

  LTemp := FItems[AIndex1];
  FItems[AIndex1] := FItems[AIndex2];
  FItems[AIndex2] := LTemp;
end;

function TDObjectListBase.Extract(const AItem: TObject): TObject;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AItem);
  if LIndex < 0 then
    Exit(nil);

  Result := FItems[LIndex];
  DeleteAtChecked(LIndex, lnExtracted);
end;

function TDObjectListBase.ExtractAt(const AIndex: Integer): TObject;
begin
  CheckIndex(AIndex);
  Result := FItems[AIndex];
  DeleteAtChecked(AIndex, lnExtracted);
end;

procedure TDObjectListBase.FinalizeItem(
  const AItem: TObject;
  const AAction: TDListNotification);
begin
  Notify(AItem, AAction);

  if FOwnsObjects and (AAction <> lnExtracted) then
    AItem.Free;
end;

function TDObjectListBase.FindIndex(const APredicate: TDObjectBasePredicate): Integer;
begin
  if not Assigned(APredicate) then
    Exit(-1);

  Result := InternalFindIndex(InvokeBasePredicate, @APredicate);
end;

function TDObjectListBase.FindLastIndex(const APredicate: TDObjectBasePredicate): Integer;
begin
  if not Assigned(APredicate) then
    Exit(-1);

  Result := InternalFindLastIndex(InvokeBasePredicate, @APredicate);
end;

function TDObjectListBase.First: TObject;
begin
  Result := InternalFirst;
end;

function TDObjectListBase.GetEnumerator: TDObjectListBaseEnumerator;
begin
  Result := TDObjectListBaseEnumerator.Create(Self);
end;

function TDObjectListBase.GetItem(const AIndex: Integer): TObject;
begin
  CheckIndex(AIndex);
  Result := FItems[AIndex];
end;

function TDObjectListBase.IndexOf(const AItem: TObject): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if FItems[I] = AItem then
      Exit(I);
end;

procedure TDObjectListBase.Insert(const AIndex: Integer; const AItem: TObject);
var
  LMoveCount: Integer;
begin
  CheckInsertIndex(AIndex);

  if Count = Capacity then
    Grow;

  LMoveCount := Count - AIndex;
  if LMoveCount > 0 then
    System.Move(FItems[AIndex], FItems[AIndex + 1], LMoveCount * SizeOf(Pointer));

  FItems[AIndex] := AItem;
  CountInternal := Count + 1;
  Notify(AItem, lnAdded);
end;

procedure TDObjectListBase.InternalAddRange(const AItems; const ACount: Integer);
var
  LOldCount: Integer;
  I: Integer;
begin
  if ACount <= 0 then
    Exit;

  LOldCount := Count;
  if LOldCount + ACount > Capacity then
    Capacity := LOldCount + ACount;

  System.Move(AItems, FItems[LOldCount], ACount * SizeOf(Pointer));
  CountInternal := LOldCount + ACount;

  for I := LOldCount to Count - 1 do
    Notify(FItems[I], lnAdded);
end;

function TDObjectListBase.InternalAny(
  const ACallback: TDObjectMatchCallback;
  const AContext: Pointer): Boolean;
begin
  Result := InternalFindIndex(ACallback, AContext) >= 0;
end;

function TDObjectListBase.InternalCountIf(
  const ACallback: TDObjectMatchCallback;
  const AContext: Pointer): Integer;
var
  I: Integer;
begin
  Result := 0;
  if not Assigned(ACallback) then
    Exit;

  for I := 0 to Count - 1 do
    if ACallback(FItems[I], AContext) then
      Inc(Result);
end;

function TDObjectListBase.InternalFindIndex(
  const ACallback: TDObjectMatchCallback;
  const AContext: Pointer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if not Assigned(ACallback) then
    Exit;

  for I := 0 to Count - 1 do
    if ACallback(FItems[I], AContext) then
      Exit(I);
end;

function TDObjectListBase.InternalFindLastIndex(
  const ACallback: TDObjectMatchCallback;
  const AContext: Pointer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if not Assigned(ACallback) then
    Exit;

  for I := Count - 1 downto 0 do
    if ACallback(FItems[I], AContext) then
      Exit(I);
end;

function TDObjectListBase.InternalFirst: TObject;
begin
  CheckIndex(0);
  Result := FItems[0];
end;

function TDObjectListBase.InternalLast: TObject;
begin
  CheckIndex(Count - 1);
  Result := FItems[Count - 1];
end;

function TDObjectListBase.InternalRemoveWhere(
  const ACallback: TDObjectMatchCallback;
  const AContext: Pointer): Integer;
var
  AReadIndex: Integer;
  AWriteIndex: Integer;
  AKeptCount: Integer;
  AItem: TObject;
begin
  Result := 0;
  if not Assigned(ACallback) then
    Exit;

  AWriteIndex := Count - 1;

  for AReadIndex := Count - 1 downto 0 do
  begin
    AItem := FItems[AReadIndex];

    if ACallback(AItem, AContext) then
    begin
      FItems[AReadIndex] := nil;
      FinalizeItem(AItem, lnRemoved);
      Inc(Result);
    end
    else
    begin
      if AWriteIndex <> AReadIndex then
      begin
        FItems[AWriteIndex] := AItem;
        FItems[AReadIndex] := nil;
      end;

      Dec(AWriteIndex);
    end;
  end;

  if Result = 0 then
    Exit;

  AKeptCount := Count - Result;

  { Compactacao em lote: evita chamar Delete para cada item removido, o que
    geraria uma cascata de movimentacoes O(n*m). O percurso de tras para frente
    preserva a ordem dos itens mantidos sem precisar de vetor temporario. }
  if AKeptCount > 0 then
    System.Move(FItems[AWriteIndex + 1], FItems[0], AKeptCount * SizeOf(Pointer));

  for AReadIndex := AKeptCount to Count - 1 do
    FItems[AReadIndex] := nil;

  CountInternal := AKeptCount;
end;

function TDObjectListBase.Last: TObject;
begin
  Result := InternalLast;
end;

procedure TDObjectListBase.Move(const ACurIndex, ANewIndex: Integer);
var
  LItem: TObject;
  LMoveCount: Integer;
begin
  CheckIndex(ACurIndex);
  CheckIndex(ANewIndex);

  if ACurIndex = ANewIndex then
    Exit;

  LItem := FItems[ACurIndex];

  if ACurIndex < ANewIndex then
  begin
    LMoveCount := ANewIndex - ACurIndex;
    System.Move(FItems[ACurIndex + 1], FItems[ACurIndex], LMoveCount * SizeOf(Pointer));
  end
  else
  begin
    LMoveCount := ACurIndex - ANewIndex;
    System.Move(FItems[ANewIndex], FItems[ANewIndex + 1], LMoveCount * SizeOf(Pointer));
  end;

  FItems[ANewIndex] := LItem;
end;

procedure TDObjectListBase.Notify(
  const AItem: TObject;
  const AAction: TDListNotification);
begin
end;

function TDObjectListBase.Remove(const AItem: TObject): Integer;
begin
  Result := IndexOf(AItem);
  if Result >= 0 then
    DeleteAtChecked(Result, lnRemoved);
end;

function TDObjectListBase.RemoveWhere(const APredicate: TDObjectBasePredicate): Integer;
begin
  if not Assigned(APredicate) then
    Exit(0);

  Result := InternalRemoveWhere(InvokeBasePredicate, @APredicate);
end;

procedure TDObjectListBase.SetItem(const AIndex: Integer; const AValue: TObject);
var
  LOldItem: TObject;
begin
  CheckIndex(AIndex);
  LOldItem := FItems[AIndex];

  if LOldItem = AValue then
    Exit;

  FItems[AIndex] := AValue;
  FinalizeItem(LOldItem, lnDeleted);
  Notify(AValue, lnAdded);
end;

{ TDObjectListEnumerator<T> }

constructor TDObjectListEnumerator<T>.Create(const AList: TDObjectListBase);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TDObjectListEnumerator<T>.GetCurrent: T;
begin
  Result := T(FList[FIndex]);
end;

function TDObjectListEnumerator<T>.MoveNext: Boolean;
begin
  Result := FIndex < FList.Count - 1;
  if Result then
    Inc(FIndex);
end;

{ TDObjectList<T> }

function TDObjectList<T>.Add(const AItem: T): Integer;
begin
  Result := inherited Add(AItem);
end;

procedure TDObjectList<T>.AddRange(const AItems: array of T);
begin
  if Length(AItems) > 0 then
    inherited InternalAddRange(AItems[0], Length(AItems));
end;

function TDObjectList<T>.Any(const APredicate: TDObjectPredicate<T>): Boolean;
begin
  if not Assigned(APredicate) then
    Exit(False);

  Result := inherited Any(
    function(const AItem: TObject): Boolean
    begin
      Result := APredicate(T(AItem));
    end
  );
end;

function TDObjectList<T>.Contains(const AItem: T): Boolean;
begin
  Result := inherited Contains(AItem);
end;

function TDObjectList<T>.CountIf(
  const APredicate: TDObjectPredicate<T>): Integer;
begin
  if not Assigned(APredicate) then
    Exit(0);

  Result := inherited CountIf(
    function(const AItem: TObject): Boolean
    begin
      Result := APredicate(T(AItem));
    end
  );
end;

function TDObjectList<T>.Extract(const AItem: T): T;
begin
  Result := T(inherited Extract(AItem));
end;

function TDObjectList<T>.ExtractAt(const AIndex: Integer): T;
begin
  Result := T(inherited ExtractAt(AIndex));
end;

function TDObjectList<T>.FindIndex(
  const APredicate: TDObjectPredicate<T>): Integer;
begin
  if not Assigned(APredicate) then
    Exit(-1);

  Result := inherited FindIndex(
    function(const AItem: TObject): Boolean
    begin
      Result := APredicate(T(AItem));
    end
  );
end;

function TDObjectList<T>.FindLastIndex(
  const APredicate: TDObjectPredicate<T>): Integer;
begin
  if not Assigned(APredicate) then
    Exit(-1);

  Result := inherited FindLastIndex(
    function(const AItem: TObject): Boolean
    begin
      Result := APredicate(T(AItem));
    end
  );
end;

function TDObjectList<T>.First: T;
begin
  Result := T(inherited InternalFirst);
end;

function TDObjectList<T>.GetEnumerator: TDObjectListEnumerator<T>;
begin
  Result := TDObjectListEnumerator<T>.Create(Self);
end;

function TDObjectList<T>.GetTypedItem(const AIndex: Integer): T;
begin
  Result := T(inherited Items[AIndex]);
end;

function TDObjectList<T>.IndexOf(const AItem: T): Integer;
begin
  Result := inherited IndexOf(AItem);
end;

procedure TDObjectList<T>.Insert(const AIndex: Integer; const AItem: T);
begin
  inherited Insert(AIndex, AItem);
end;

function TDObjectList<T>.Last: T;
begin
  Result := T(inherited InternalLast);
end;

function TDObjectList<T>.Remove(const AItem: T): Integer;
begin
  Result := inherited Remove(AItem);
end;

function TDObjectList<T>.RemoveWhere(
  const APredicate: TDObjectPredicate<T>): Integer;
begin
  if not Assigned(APredicate) then
    Exit(0);

  Result := inherited RemoveWhere(
    function(const AItem: TObject): Boolean
    begin
      Result := APredicate(T(AItem));
    end
  );
end;

procedure TDObjectList<T>.SetTypedItem(
  const AIndex: Integer;
  const AValue: T);
begin
  inherited Items[AIndex] := AValue;
end;

end.

