unit udCollections.Common;

interface

uses
  System.SysUtils;

type
  { Predicates }

  TDPredicate<T> = reference to function(const AValue: T): Boolean;
  TDPredicateMethod<T> = function(const AValue: T): Boolean of object;

  { Actions }

  TDAction<T> = reference to procedure(const AValue: T);
  TDActionMethod<T> = procedure(const AValue: T) of object;

  { Selectors }

  TDSelector<T, TResult> = reference to function(const AValue: T): TResult;
  TDSelectorMethod<T, TResult> = function(const AValue: T): TResult of object;

  { Comparers }

  TDComparer<T> = reference to function(const Left, Right: T): Integer;

  TDComparerMethod<T> = function(const Left, Right: T): Integer of object;

  { Aggregate }

  TDAggregate<T, TResult> = reference to function(const Current: TResult;
    const Item: T): TResult;

  TDAggregateMethod<T, TResult> = function(const Current: TResult;
    const Item: T): TResult of object;

  { Object Delegates }

  TObjectPredicate = reference to function(const Obj: TObject): Boolean;

  TObjectAction = reference to procedure(const Obj: TObject);

  TObjectSelector<TResult> = reference to function(const Obj: TObject): TResult;

  TObjectComparer = reference to function(const Left, Right: TObject): Integer;

implementation

end.
