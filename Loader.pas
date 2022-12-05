unit Loader;

interface

uses
  System.Classes, System.SyncObjs,
  MainForm;

type
  TLoader = class(TThread)
  private
    // переменная для отслеживания изменений
    FLastVersion: Integer;
    // интервал обновления
    FInterval: Cardinal;
    FLogger: TLogger;
    // небольшая функция запроса номера последнего изменения
    function GetCurrentVersion: Word;
    // процедуры добавления записи, полученной из базы, в дерево
    procedure AddObject(Id: Integer; Name, Comment: String; Select: Boolean = False);
    procedure AddValue(ObjId: Integer; DT: TDateTime; Value1: Integer; Value2: String; Value3: Double; Select: Boolean = False);
    // процедуры первоначального и повтороного получения данных
    procedure GetInitialData;
    procedure GetChanges;
    procedure Log(Text: String; SetTimeStamp: Boolean = True);
  protected
    procedure Execute; override;
    // сеттер интервала
    procedure SetInterval(Value: Cardinal);
  public
    // события, при установке которых что-то делает
    StartEvent, UpdateEvent: TEvent;
    property Interval: Cardinal write SetInterval;
    constructor Create(Interval: Cardinal; Logger: TLogger = nil);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, VirtualTrees;

// добавление записи test_Object, полученной из базы, в дерево
// параметры: поля id, name и comment объекта, нужно ли выделять
procedure TLoader.AddObject(Id: Integer; Name, Comment: String; Select: Boolean = False);
var
  Data: PTreeNode;
  XNode: PVirtualNode;
begin
  // добавить узел и прописать данные Объекта
  Synchronize(procedure
    begin
      XNode := FmMain.VSTree.AddChild(FmMain.VSTree.RootNode);
      Data := FmMain.VSTree.GetNodeData(XNode);
      Data.NodeType := ntObject;
      Data.Id := Id;
      Data.Name := Name;
      Data.Comment := Comment;
      // и перевести фокус
      if Select then
        fmMain.vstree.Selected[XNode] := True;
    end);
    Log('Получен объект ' + IntTostr(Id) + ' - name: ' + Name + ', comment: ' + Comment);
end;

// добавление записи test_ObjectValue, полученной из базы, в дерево
// параметры: поля obj_id, date_time, value1..3 объекта, нужно ли выделять
procedure TLoader.AddValue(ObjId: Integer; DT: TDateTime; Value1: Integer;
  Value2: String; Value3: Double; Select: Boolean = False);
var
  Data: PTreeNode;
  XNode: PVirtualNode;
  Node: PVirtualNode;
begin
  // поиск узла по id объекта перебором
  Node := FmMain.VSTree.GetFirst;
  while Assigned(Node) do
  begin
    Data := Node.GetData;
    if (Data.NodeType = ntObject) and (Data.Id=ObjId) then
      Break;
    // не нашелся - идем дальше, не перебирая дочерние
    Node := Node.NextSibling;
  end;
  // ничего не нашлось - выход по-тихому
  if not Assigned(Node) then
    Exit;
  // иначе - создать дочерний узел
  Synchronize(procedure
    begin
      XNode := FmMain.VSTree.AddChild(Node);
      Data := FmMain.VSTree.GetNodeData(XNode);
      // и заполнить его данными
      Data.NodeType := ntObjectValue;
      Data.ObjectId := ObjId;
      Data.DT := DT;
      Data.Value1 := Value1;
      Data.Value2 := Value2;
      Data.Value3 := Value3;
      // по дефолту узел свернут, развернуть
      FmMain.VSTree.Expanded[Node] := True;
      // и перевести фокус
      if Select then
        FmMain.VSTree.Selected[XNode] := True;
    end);
  // write to log
  Log('Получены даные для объекта ' + IntTostr(ObjId));
  // second row with some tabs ahead
  Log(#9#9#9#9 + '[' + DateTimeToStr(DT) + '] value1: ' + IntToStr(Value1) + ', value2: ' +
      Value2 + ', value3: ' + FloatToStr(Value3), False);
end;

constructor TLoader.Create(Interval: Cardinal; Logger: TLogger = nil);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  if Assigned(Logger) then
    FLogger := Logger;
  // в конструкторе устанавливается интервал
  FInterval := Interval;
  // инициализируются события (автосброс, отключенное)
  StartEvent := TEvent.Create(nil, False, False, '');
  UpdateEvent := TEvent.Create(nil, False, False, '');
  Log('--', False);
  Log('Программа запущена');
end;

destructor TLoader.Destroy;
begin
  StartEvent.Free;
  UpdateEvent.Free;
  inherited;
end;

procedure TLoader.GetChanges;
begin
  with FmMain.ADOQuery do
    begin
      // сначала обновить инфу об объектах
      // для получения сведений об изменениях используется функция CHANGETABLE(CHANGES...)
      // отслеживается только insert, поэтому соединяем внутренним джойном
      SQL.Clear;
      SQL.Add('SELECT ct.id, o.name, o.comment FROM test_Object AS o');
      SQL.Add('INNER JOIN');
      SQL.Add('CHANGETABLE(CHANGES test_Object, ' + IntToStr(FLastVersion) +') AS ct');
      SQL.Add('ON ct.id=o.id;');
      Active := True;
      Synchronize(procedure
        begin
          FmMain.VSTree.BeginUpdate;
        end);
      while not Eof do
        begin
          AddObject(FieldByName('id').AsInteger, FieldByName('name').AsString,
                    FieldByName('comment').AsString, True);
          Next;
        end;
      // потом обновить инфу о значениях
      SQL.Clear;
      SQL.Add('SELECT ct.obj_id, ct.date_time, ov.value1, ov.value2, ov.value3');
      SQL.Add('FROM test_ObjectValue AS ov');
      SQL.Add('RIGHT JOIN');
      sql.Add('CHANGETABLE(CHANGES test_ObjectValue, ' + IntToStr(FLastVersion) +') AS ct');
      // тут составной первичный ключ
      SQL.Add('ON (ct.obj_id=ov.obj_id) AND (ct.date_time=ov.date_time);');
      Active := True;
      while not Eof do
        begin
          AddValue(FieldByName('obj_id').AsInteger, FieldByName('date_time').AsDateTime,
                   FieldByName('value1').AsInteger, FieldByName('value2').AsString,
                   FieldByName('value3').AsFloat, True);
          Next;
        end;
        Close;
      FLastVersion := GetCurrentVersion;
      Log('Текущая транзакция: ' + IntToStr(FLastVersion));
    end;
    // отобразить инфу об изменениях
    Synchronize(procedure
      begin
        FmMain.VSTree.EndUpdate;
        FmMain.StatusBar.Panels[2].Text := 'Transaction: ' + IntToStr(FLastVersion);
      end);
end;

// получение текущей версии
// возвращает: номер текущей версии
function TLoader.GetCurrentVersion: Word;
begin
  with FmMain.ADOQuery do
    begin
      SQL.Clear;
      // получения номера последнего изменения
      // то есть номер последней зафиксированной транзакции
      SQL.Add('SELECT CHANGE_TRACKING_CURRENT_VERSION();');
      Active := True;
      Result := Fields[0].AsInteger;
      Active := False;
    end;
end;

procedure TLoader.GetInitialData;
begin
  FLogger.Log('--', False);
  FLogger.Log('Первоначальная загрузка данных');
  with FmMain.ADOQuery do
    begin
      // сохранить текущую версию
      FLastVersion := GetCurrentVersion;
      Log('Текущая транзакция: ' + IntToStr(FLastVersion));
      SQL.Clear;
      // сначала объекты простым селектом
      SQL.Add('SELECT * FROM test_Object;');
      Active := True;
      while not Eof do
        begin
          // добавить объект как узел дерева (без фокусировки, чтобы не мигало)
          AddObject(FieldByName('id').AsInteger, FieldByName('name').AsString,
                    FieldByName('comment').AsString);
          Next;
        end;
      // а затем значения
      SQL.Clear;
      SQL.Add('SELECT * FROM test_ObjectValue;');
      Active := True;
      while not Eof do
        begin
          // добавить значение в дерево (без фокусировки)
          AddValue(FieldByName('obj_id').AsInteger, FieldByName('date_time').AsDateTime,
                   FieldByName('value1').AsInteger, FieldByName('value2').AsString,
                   FieldByName('value3').AsFloat);
          Next;
        end;
      Close;
    end;
    Synchronize(procedure
      begin
        // показать номер транзакции
        FmMain.StatusBar.Panels[2].Text := 'Transaction: ' + IntToStr(FLastVersion);
      end);
end;

procedure TLoader.Log(Text: String; SetTimeStamp: Boolean);
begin
  if Assigned(FLogger) then
    FLogger.Log(Text, SetTimeStamp);
end;

procedure TLoader.Execute;
begin
  {$IFDEF DEBUG}
    NameThreadForDebugging('SQL-Loader-Thread');
  {$ENDIF}
  // первоначальная загрузка данных
  // ждем команды стартовать
  StartEvent.WaitFor(INFINITE);
  GetInitialData;
  // а после этого цикл ожидания наступления запроса обновлений или выхода
  while not Terminated do
    begin
      // ждем, пока не установится событие
      UpdateEvent.WaitFor(FInterval);
      // поток могли завершить, пока он был в бесконечном ожидании,
      // значит нужно проверить на завершенность
      if Terminated then Exit;
      // если нет подключения к базе или что-то выполняется, то снова ждать
      if not FmMain.ADOCnxn.Connected or FmMain.ADOQuery.Active then Continue;
      // записать в лог сообщения о времени запроса изменения
      Log('--', False);
      Log('Запрос обновления данных');
      // и вывести тоже самое на статусбаре
      Synchronize(procedure
        begin
          FmMain.StatusBar.Panels[1].Text := 'Updated: ' + TimeToStr(Now);
        end);
      // а было ли изменение?
      if FLastVersion <> GetCurrentVersion then
        GetChanges;
    end;
end;

// установка интервала обновлений
procedure TLoader.SetInterval(Value: Cardinal);
begin
  // в случае нуля - бесконечное ожидание
  if Value = 0 then
    FInterval := INFINITE
  else
    begin
      // если меняется с бесконечного на определенное,
      // после сохранения нового интервала нужно установить событие
      FInterval := Value;
      UpdateEvent.SetEvent;
    end;
end;


end.
