unit CompileCopyPlugin;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, ToolsAPI;

type
  TCompileNotifier = class(TInterfacedObject, IOTACompileNotifier)
  public
    procedure ProjectCompileStarted(const Project: IOTAProject;
      Mode: TOTACompileMode);
    procedure ProjectCompileFinished(const Project: IOTAProject;
      Result: TOTACompileResult);
    procedure ProjectGroupCompileFinished(Result: TOTACompileResult);
    procedure ProjectGroupCompileStarted(Mode: TOTACompileMode);
  end;

procedure Register;

implementation

uses System.StrUtils;

var
  CompileNotifierIndex: Integer = -1;

  { TCompileNotifier }

procedure TCompileNotifier.ProjectCompileFinished(const Project: IOTAProject;
  Result: TOTACompileResult);
begin

end;

procedure TCompileNotifier.ProjectCompileStarted(const Project: IOTAProject;
  Mode: TOTACompileMode);
var
  ProjectDir, SourceFile, DestFile, FileName: string;
  ModuleInfo: IOTAModuleInfo;
  MsgServices: IOTAMessageServices;
  DenyExts: TArray<string>;
  cnt: Integer;
begin
  // コンパイル前にコピーしたい場合はここに記述（Cancel := True で中止も可能）
  if Project = nil then
    Exit;
  if Project.GetModuleCount = 0 then
    Exit;

  DenyExts := ['.pas', '.fmx', '.dfm'];
  ProjectDir := ExtractFilePath(Project.FileName);

  // IDEのメッセージウィンドウ取得（デバッグ表示用）
  Supports(BorlandIDEServices, IOTAMessageServices, MsgServices);

  if MsgServices <> nil then
    MsgServices.AddTitleMessage('=== 複製ファイル一覧 ===');

  cnt := 1;
  // 2. プロジェクト内のモジュール（ファイル）をループ処理
  for var I := 0 to Project.GetModuleCount - 1 do
  begin
    ModuleInfo := Project.GetModule(I);
    if ModuleInfo <> nil then
    begin
      FileName := ExtractFileName(ModuleInfo.FileName);
      if FileName = '' then
        continue;
      if MatchText(ExtractFileExt(FileName), DenyExts) then
        continue;

      SourceFile := ModuleInfo.FileName;

      // 出力ディレクトリを取得（構成やプラットフォームに応じて取得可能）
      // 簡易的にプロジェクトフォルダ直下や出力先に指定
      DestFile := TPath.Combine([ProjectDir, Project.CurrentPlatform,
        Project.CurrentConfiguration, FileName]);

      try
        ForceDirectories(ExtractFilePath(DestFile));
        TFile.Copy(SourceFile, DestFile, True); // 上書きコピー
        MsgServices.AddTitleMessage(Format('[%d] %s', [cnt, DestFile]));
      except
        on E: Exception do
          MsgServices.AddTitleMessage(Format('[%d] コピー失敗 %s: %s',
            [cnt, FileName, E.Message]));
      end;
      inc(cnt);
    end;
  end;
end;

procedure TCompileNotifier.ProjectGroupCompileFinished
  (Result: TOTACompileResult);
begin

end;

procedure TCompileNotifier.ProjectGroupCompileStarted(Mode: TOTACompileMode);
begin

end;

{ 登録および解除処理 }

procedure Register;
var
  CompileServices: IOTACompileServices;
begin
  if Supports(BorlandIDEServices, IOTACompileServices, CompileServices) then
  begin
    CompileNotifierIndex := CompileServices.AddNotifier
      (TCompileNotifier.Create);
  end;
end;

initialization

finalization

if (CompileNotifierIndex <> -1) and (BorlandIDEServices <> nil) then
begin
  var
    CompileServices: IOTACompileServices;
  if Supports(BorlandIDEServices, IOTACompileServices, CompileServices) then
    CompileServices.RemoveNotifier(CompileNotifierIndex);
end;

end.
