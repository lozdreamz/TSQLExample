unit MainForm;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.IniFiles,
  Vcl.Forms, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin, Vcl.Mask,
  Data.DB, Data.Win.ADODB,
  VirtualTrees;

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

  TLogger = class
  private
    FFormatSettings: TFormatSettings;
    FLogFileStream: TFileStream;
  public
    constructor Create(LogPath: String);
    destructor Destroy; override;
    procedure Log(Text: String; SetTimeStamp: Boolean = True);
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
    procedure VSTreeBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
  public
    // ini-файл для хранения настроек
    ConfigFile: TIniFile;
    // процедуры загрузки, сохранения и применения настроек
    procedure LoadConfig;
    procedure SaveConfig;
    procedure ApplyConfig;
  end;

var
  FmMain: TFmMain;


implementation

uses
  Vcl.Graphics, Vcl.Dialogs,
  DataLoader;

var
  t: TDataLoader;
  l: TLogger;

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
    Exit;
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
  l.Free;
  if Assigned(t) and t.Started then
    begin
      // разбудить и убить поток
      t.UpdateEvent.SetEvent;
      t.Terminate;
//      t.WaitFor;
//      t.Free;
    end;
end;

procedure TFmMain.FormCreate(Sender: TObject);
var
  AppPath, LogPath: String;
begin
  AppPath := ExtractFilePath(Application.ExeName);
  ConfigFile := TIniFile.Create(AppPath + 'config.ini');
  LogPath := AppPath + 'log.txt';
  l := TLogger.Create(LogPath);
  t := TDataLoader.Create(0, l);
  LoadConfig;
  ApplyConfig;
end;

// окрашивание строк с объектами
procedure TFmMain.VSTreeBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data: PTreeNode;
begin
  Data := VSTree.GetNodeData(Node);
  if Data.NodeType = ntObject then
    begin
      TargetCanvas.Brush.Color := clAppWorkSpace;
      TargetCanvas.FillRect(CellRect);
    end;
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
  Data := VSTree.GetNodeData(Node);
  if Assigned(Data) then
    begin
        // хоть строки и освобождаются автоматически,
        // если их не обнулить, будет утечка
        Data.Name := '';
        Data.Comment := '';
        Data.Value2 := '';
    end;
end;

procedure TFmMain.VSTreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TTreeNode);
end;

// определение текста узла VirtualStringTree
procedure TFmMain.VSTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PTreeNode;
begin
  CellText := '';
  Data := VSTree.GetNodeData(Node);
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

{ TLogger }

constructor TLogger.Create(LogPath: String);
var
  Mode: Word;
begin
  // create or open log file and seek to end
  if FileExists(LogPath) then
    Mode := fmShareDenyWrite or fmOpenWrite
  else
    Mode := fmShareDenyWrite or fmCreate;
  FLogFileStream := TFileStream.Create(LogPath,  Mode);
  FLogFileStream.Seek(0, soFromEnd);
  // set timestamp format
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.LongTimeFormat := 'hh:nn:ss:zzz';
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
end;

destructor TLogger.Destroy;
begin
  FreeAndNil(FLogFileStream);
end;

procedure TLogger.Log(Text: String; SetTimeStamp: Boolean = True);
var
  TimeStamp: String;
  w: TStreamWriter;
begin
   // divider
   if Text = '--' then
     Text := '---------------------------------------------------';
   if SetTimeStamp then
     Text := DateTimeToStr(Now, FFormatSettings) + ': ' + Text;
   w := TStreamWriter.Create(FLogFileStream, TEncoding.UTF8);
   w.WriteLine(Text);
   w.Free;
end;

end.
