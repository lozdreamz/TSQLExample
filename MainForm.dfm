object FmMain: TFmMain
  Left = 494
  Top = 247
  Caption = 'T-SQL Example'
  ClientHeight = 396
  ClientWidth = 799
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object PnTop: TPanel
    Left = 0
    Top = 0
    Width = 799
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 793
    object BtnStart: TButton
      Left = 24
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 0
      OnClick = BtnStartClick
    end
    object BtnUpdate: TButton
      Left = 105
      Top = 8
      Width = 97
      Height = 25
      Caption = 'Manual update'
      TabOrder = 1
      OnClick = BtnUpdateClick
    end
    object BtnExpand: TButton
      Left = 256
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Expand all'
      TabOrder = 2
      OnClick = BtnExpandClick
    end
    object BtnCollapse: TButton
      Left = 337
      Top = 8
      Width = 75
      Height = 25
      Caption = 'Collapse all'
      TabOrder = 3
      OnClick = BtnCollapseClick
    end
  end
  object VSTree: TVirtualStringTree
    Left = 0
    Top = 41
    Width = 633
    Height = 336
    Align = alClient
    Colors.BorderColor = 15987699
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 15385233
    Colors.DropTargetColor = 15385233
    Colors.DropTargetBorderColor = 15385233
    Colors.FocusedSelectionColor = 15385233
    Colors.FocusedSelectionBorderColor = 15385233
    Colors.GridLineColor = 15987699
    Colors.HeaderHotColor = clBlack
    Colors.HotColor = clBlack
    Colors.SelectionRectangleBlendColor = 15385233
    Colors.SelectionRectangleBorderColor = 15385233
    Colors.SelectionTextColor = clBlack
    Colors.TreeLineColor = 9471874
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = clWhite
    Colors.UnfocusedSelectionBorderColor = clWhite
    Header.AutoSizeIndex = 0
    Header.Options = [hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    TabOrder = 1
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowHorzGridLines, toShowRoot, toShowVertGridLines, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnChange = VSTreeChange
    OnFocusChanged = VSTreeFocusChanged
    OnFreeNode = VSTreeFreeNode
    OnGetText = VSTreeGetText
    OnPaintText = VSTreePaintText
    OnGetNodeDataSize = VSTreeGetNodeDataSize
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable, coStyleColor]
        Position = 0
        Width = 320
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable, coStyleColor]
        Position = 1
        Text = 'Value1'
        Width = 80
      end
      item
        Options = [coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coVisible, coAllowFocus, coEditable, coStyleColor]
        Position = 2
        Text = 'Value2'
        Width = 120
      end
      item
        Position = 3
        Text = 'Value3'
        Width = 80
      end>
  end
  object BoxConfig: TGroupBox
    Left = 633
    Top = 41
    Width = 166
    Height = 336
    Align = alRight
    Caption = 'Settings:'
    TabOrder = 2
    ExplicitLeft = 627
    ExplicitHeight = 327
    object LbInterval: TLabel
      Left = 6
      Top = 204
      Width = 152
      Height = 13
      Caption = 'Refresh interval (0 for manual):'
    end
    object LbSeconds: TLabel
      Left = 133
      Top = 226
      Width = 5
      Height = 13
      Caption = 's'
    end
    object EdHost: TLabeledEdit
      Left = 6
      Top = 39
      Width = 155
      Height = 21
      EditLabel.Width = 26
      EditLabel.Height = 13
      EditLabel.Caption = 'Host:'
      TabOrder = 0
      Text = ''
    end
    object EdUser: TLabeledEdit
      Left = 6
      Top = 79
      Width = 155
      Height = 21
      EditLabel.Width = 26
      EditLabel.Height = 13
      EditLabel.Caption = 'User:'
      TabOrder = 1
      Text = ''
    end
    object EdPassword: TLabeledEdit
      Left = 6
      Top = 123
      Width = 155
      Height = 21
      EditLabel.Width = 50
      EditLabel.Height = 13
      EditLabel.Caption = 'Password:'
      TabOrder = 2
      Text = ''
    end
    object SpinEdInterval: TSpinEdit
      Left = 6
      Top = 222
      Width = 121
      Height = 22
      MaxValue = 120
      MinValue = 0
      TabOrder = 4
      Value = 0
    end
    object EdDatabase: TLabeledEdit
      Left = 6
      Top = 167
      Width = 155
      Height = 21
      EditLabel.Width = 50
      EditLabel.Height = 13
      EditLabel.Caption = 'Database:'
      TabOrder = 3
      Text = ''
    end
    object BtnUpdateSettings: TButton
      Left = 16
      Top = 264
      Width = 113
      Height = 25
      Caption = 'Update settings'
      TabOrder = 5
      OnClick = BtnUpdateSettingsClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 377
    Width = 799
    Height = 19
    Panels = <
      item
        Text = 'Disconnected'
        Width = 100
      end
      item
        Width = 200
      end
      item
        Width = 50
      end>
    ExplicitTop = 368
    ExplicitWidth = 793
  end
  object ADOQuery: TADOQuery
    Connection = ADOCnxn
    Parameters = <>
    Left = 104
    Top = 56
  end
  object ADOCnxn: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Password=<YourStrong@Passw0rd>;Persist Secur' +
      'ity Info=True;User ID=SA;Initial Catalog=TestDB;Data Source=loca' +
      'lhost'
    LoginPrompt = False
    Mode = cmShareDenyNone
    Provider = 'SQLOLEDB.1'
    AfterConnect = ADOCnxnAfterConnect
    AfterDisconnect = ADOCnxnAfterDisconnect
    Left = 24
    Top = 64
  end
end
