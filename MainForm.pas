unit MainForm;

interface

uses
  System.SysUtils, System.Classes, System.UITypes, System.IniFiles, System.SyncObjs,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Grids, Vcl.DBCtrls, Vcl.DBGrids, Data.DB, Data.Win.ADODB,
  VirtualTrees, Vcl.Samples.Spin, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Mask;

type
  TNodeType = (ntObject, ntObjectValue);

  // структура хранения инфы узла дерева
  // для упрощения - одна структура и для объекта, и для дочерних значений
  PTreeNode = ^TTreeNode;
  TTreeNode = record
    // Object и Value определяются по этому полю
    NodeType: TNodeType;
    Id: Integer;
    Name: String;
    Comment: String;
    // поля, специфичные для Value
    ObjectId: Integer;
    DT: TDateTime;
    Value1: Integer;
    Value2: String;
    Value3: Double;
  end;

  TFmMain = class(TForm)
    PnTop: TPanel;
    ADOQuery: TADOQuery;
    ADOCnxn: TADOConnection;
    BtnStart: TButton;
    VSTree: TVirtualStringTree;
    BoxConfig: TGroupBox;
    EdHost: TLabeledEdit;
    EdUser: TLabeledEdit;
    EdPassword: TLabeledEdit;
    SpinEdInterval: TSpinEdit;
    EdDatabase: TLabeledEdit;
    LbInterval: TLabel;
    BtnUpdateSettings: TButton;
    LbSeconds: TLabel;
    StatusBar: TStatusBar;
    BtnUpdate: TButton;
    BtnExpand: TButton;
    BtnCollapse: TButton;
    procedure BtnStartClick(Sender: TObject);
    procedure VSTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure VSTreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTreeGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure VSTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure VSTreePaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnUpdateSettingsClick(Sender: TObject);
    procedure ADOCnxnAfterConnect(Sender: TObject);
    procedure ADOCnxnAfterDisconnect(Sender: TObject);
    procedure BtnUpdateClick(Sender: TObject);
    procedure BtnExpandClick(Sender: TObject);
    procedure BtnCollapseClick(Sender: TObject);
  private
    { Private declarations }
  public
    // ini-файл для хранения настроек
    ConfigFile: TIniFile;
    // процедуры загрузки, сохранения и применения настроек
    procedure LoadConfig;
    procedure SaveConfig;
    procedure ApplyConfig;
  end;

  // класс потока, обращающегося к базе
  TRequestThread = class(TThread)
  private
    // переменная для отслеживания изменений
    FLastVersion: Integer;
    // интервал обновления
    FInterval: Cardinal;
    // стрим для лог-файла
    FLogFileStream: TFileStream;
    // небольшая функция запроса номера последнего изменения
    function GetCurrentVersion: Word;
    // процедуры добавления записи, полученной из базы, в дерево
    procedure AddObject(Id: Integer; Name, Comment: String; Select: Boolean = False);
    procedure AddValue(ObjId: Integer; DT: TDateTime; Value1: Integer; Value2: String; Value3: Double; Select: Boolean = False);
    // процедуры первоначального и повтороного получения данных
    procedure GetInitialData;
    procedure GetChanges;
  protected
    procedure Execute; override;
    // сеттер интервала
    procedure SetInterval(Value: Cardinal);
  public
    // события, при установке которых что-то делает
    StartEvent, UpdateEvent: TEvent;
    property Interval: Cardinal write SetInterval;
    constructor Create(Interval: Cardinal; LogPath: String);
    destructor Destroy; override;
    // процедура записи строки в лог
    procedure Log(Text: String; SetTimeStamp: Boolean = True);
  end;

var
  FmMain: TFmMain;
  t: TRequestThread;

implementation

{$R *.dfm}

// загрузка конфига
procedure TFmMain.LoadConfig;
begin
  with ConfigFile do
    begin
      EdHost.Text := ReadString('main', 'host', '');
      EdUser.Text := ReadString('main', 'user', '');
      EdPassword.Text := ReadString('main', 'password', '');
      EdDatabase.Text := ReadString('main', 'database', '');
      SpinEdInterval.Value := ReadInteger('main', 'interval', 0);
    end;
end;

// добавление записи в лог-файл
// параметры: выводимый текст, необходимость временной метки
procedure TRequestThread.Log(Text: String; SetTimeStamp: Boolean = True);
var
  fs: TFormatSettings;
  TimeStamp: String;
  w: TStreamWriter;
begin
   // запись в лог-файл с временной меткой или без
   fs.ShortDateFormat := 'yyyy-mm-dd';
   fs.LongTimeFormat := 'hh:nn:ss:zzz';
   fs.DateSeparator := '-';
   fs.TimeSeparator := ':';
   TimeStamp := DateTimeToStr(Now, fs);
   // разделитель
   if Text = '--' then
     Text := '---------------------------------------------------';
   if SetTimeStamp then
     Text := TimeStamp + ': ' + Text;
   // StreamWriter корректно пишет строки
   w := TStreamWriter.Create(FLogFileStream, TEncoding.UTF8);
   w.WriteLine(Text);
   w.Free;
end;

// сохранение конфига в ini-файл
procedure TFmMain.SaveConfig;
begin
  with ConfigFile do
    begin
      WriteString('main', 'host', EdHost.Text);
      WriteString('main', 'user', EdUser.Text);
      WriteString('main', 'password', EdPassword.Text);
      WriteString('main', 'database', EdDatabase.Text);
      WriteInteger('main', 'interval', SpinEdInterval.Value);
    end;
end;

// добавление записи test_Object, полученной из базы, в дерево
// параметры: поля id, name и comment объекта, нужно ли выделять
procedure TRequestThread.AddObject(Id: Integer; Name, Comment: String; Select: Boolean = False);
var
  Data: PTreeNode;
  XNode: PVirtualNode;
begin
  // добавить узел и прописать данные Объекта
  Synchronize(procedure
    begin
      XNode := FmMain.VSTree.AddChild(fmMain.vstree.RootNode);
      Data := FmMain.VSTree.GetNodeData(XNode);
      Data.NodeType := ntObject;
      Data.Id := Id;
      Data.Name := Name;
      Data.Comment := Comment;
      // и перевести фокус
      if Select then
        fmMain.vstree.Selected[XNode] := True;
    end);
  // логгировать
  Log('Получен объект ' + IntTostr(Id) + ' - name: ' + Name + ', comment: ' + Comment);
end;

// добавление записи test_ObjectValue, полученной из базы, в дерево
// параметры: поля obj_id, date_time, value1..3 объекта, нужно ли выделять
procedure TRequestThread.AddValue(ObjId: Integer; DT: TDateTime; Value1: Integer;
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
  // логгировать
  Log('Получены даные для объекта ' + IntTostr(ObjId));
  // вторую строчку с отступом в несколько табов
  Log(#9#9#9#9 + '[' + DateTimeToStr(DT) + '] value1: ' + IntToStr(Value1) + ', value2: ' +
      Value2 + ', value3: ' + FloatToStr(Value3), False);
end;

// отображение статуса подключения
procedure TFmMain.ADOCnxnAfterConnect(Sender: TObject);
begin
  StatusBar.Panels[0].Text := 'Connected';
end;

procedure TFmMain.ADOCnxnAfterDisconnect(Sender: TObject);
begin
  // при отключении можно снова разрешить нажимать Start
  BtnStart.Enabled := True;
  StatusBar.Panels[0].Text := 'Disconnected';
end;

// применение конфига
procedure TFmMain.ApplyConfig;
var
  ServerName, User, Password, DBName: String;
begin
  // вначале проверить на пустоту
  if (EdHost.Text = '') or (EdDatabase.Text = '') or (EdUser.Text = '') then
    begin
      ShowMessage('Не все обязательные поля заполнены');
      Exit;
    end;
  // все ок, сначала отсоединиться от сервера
  ADOCnxn.Close;
  // установить параметры
  t.Interval := SpinEdInterval.Value * 1000;
  ServerName := EdHost.Text;
  User := EdUser.Text;
  Password := EdPassword.Text;
  DBName := EdDatabase.Text;
  ADOCnxn.ConnectionString := 'Provider=SQLOLEDB.1;' +
  'Data Source=' + ServerName + ';Initial Catalog=' + DBName +';'+
  'User ID=' + User + ';Password=' + Password + ';';
  // и попробовать подключиться к серверу
  try
    ADOCnxn.Open;
  except on e:Exception do
      MessageDlg('Error:' + #13#10 + e.Message, mtError, [mbOk],0);
  end;
end;

procedure TFmMain.BtnStartClick(Sender: TObject);
begin
  if ADOCnxn.Connected then
    begin
      VSTree.Clear;
      // получить первоначальные данные
      t.StartEvent.SetEvent;
      // первоначальные данные получены,
      // дальше запросы выполняются по событию вручную или в потоке
    end;
end;

procedure TFmMain.BtnUpdateClick(Sender: TObject);
begin
  // при запросе обновлений вручную - поднять событие
  if ADOCnxn.Connected then
    t.UpdateEvent.SetEvent;
end;

procedure TFmMain.BtnUpdateSettingsClick(Sender: TObject);
begin
  // сохранять даже некорректный конфиг перед применением
  SaveConfig;
  ApplyConfig;
end;

// сворачивание всех узлов
procedure TFmMain.BtnCollapseClick(Sender: TObject);
var
  XNode: PVirtualNode;
begin
   XNode := VSTree.GetFirst;
   while Assigned(XNode) do
     begin
       VSTRee.Expanded[XNode] := False;
       XNode := VSTree.GetNextSibling(XNode);
     end;
end;

// разворачивание всех узлов
procedure TFmMain.BtnExpandClick(Sender: TObject);
var
  XNode: PVirtualNode;
begin
   XNode := VSTree.GetFirst;
   while Assigned(XNode) do
     begin
       VSTree.Expanded[XNode] := True;
       XNode := VSTree.GetNextSibling(XNode);
     end;
end;

procedure TFmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ConfigFile.Free;
  if Assigned(t) and t.Started then
    begin
      // разбудить и убить поток
      t.UpdateEvent.SetEvent;
      t.Terminate;
    end;
end;

procedure TFmMain.FormCreate(Sender: TObject);
var
  AppPath, LogPath: String;
begin
  AppPath := ExtractFilePath(Application.ExeName);
  ConfigFile := TIniFile.Create(AppPath + 'config.ini');
  LogPath := AppPath + 'log.txt';
  t := TRequestThread.Create(0, LogPath);
  LoadConfig;
  ApplyConfig;
end;

procedure TFmMain.VSTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  VSTree.Refresh;
end;

procedure TFmMain.VSTreeFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  VSTree.Refresh;
end;

procedure TFmMain.VSTreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PTreeNode;
begin
  Data := vstree.GetNodeData(Node);
  if Assigned(Data) then
    begin
        // хоть строки и освобождаются автоматически,
        // если их не обнулить, будет утечка
        Data^.Name := '';
        Data^.Comment := '';
        Data^.Value2 := '';
    end;
end;

procedure TFmMain.VSTreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TTreeNode)
end;

// определение текста узла VirtualStringTree
procedure TFmMain.VSTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PTreeNode;
begin
  CellText := '';
  Data := vstree.GetNodeData(Node);
  // для объектов выводить только id: name, comment в первой ячейке
  if Data.NodeType = ntObject then
    begin
      if Column = 0 then
        CellText := IntToStr(Data.Id) + ': ' + Data.Name + ', ' + Data.Comment
    end
  else
    // для значений выводить все кроме id объекта
    case Column of
      0: CellText := DateTimeToStr(Data.DT);
      1: CellText := IntToStr(Data.Value1);
      2: CellText := Data.Value2;
      3: CellText := FloatToStr(Data.Value3);
    end;
end;

// оформление текста узла VirtualStingTree
procedure TFmMain.VSTreePaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Data: PTreeNode;
begin
  // объекты выделять жирным
  Data := Sender.GetNodeData(Node);
  if Data.NodeType = ntObject then
    begin
      TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
    end;

end;

{ TUpdadeThread }

constructor TRequestThread.Create(Interval: Cardinal; LogPath: String);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  // в конструкторе устанавливается интервал
  FInterval := Interval;
  // инициализируются события (автосброс, отключенное)
  StartEvent := TEvent.Create(nil, False, False, '');
  UpdateEvent := TEvent.Create(nil, False, False, '');
  // создаётся/открывается лог-файл (с промоткой до конца)
  if FileExists(LogPath) then
    FLogFileStream := TFileStream.Create(LogPath,  fmOpenWrite or fmShareDenyWrite)
  else
    FLogFileStream := TFileStream.Create(LogPath,  fmCreate or fmShareDenyWrite);
  FLogFileStream.Seek(0, soFromEnd);
  Log('--', False);
  Log('Программа запущена');
end;

destructor TRequestThread.Destroy;
begin
  StartEvent.Free;
  UpdateEvent.Free;
  FreeAndNil(FLogFileStream);
  inherited;
end;

procedure TRequestThread.GetChanges;
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
function TRequestThread.GetCurrentVersion: Word;
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

procedure TRequestThread.GetInitialData;
begin
  Log('--', False);
  Log('Первоначальная загрузка данных');
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

procedure TRequestThread.Execute;
begin
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
procedure TRequestThread.SetInterval(Value: Cardinal);
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
