unit MCP.Server;

interface

uses
  System.JSON, System.SysUtils, System.Generics.Collections, MCP.Types;

type
  TMCServer = class
  private
    FTools: TDictionary<string, TMCPTool>;
    FInitialized: Boolean;
    procedure HandleInitialize(const AId: TJSONValue; const AParams: TJSONObject);
    procedure HandleToolsList(const AId: TJSONValue; const AParams: TJSONObject);
    procedure HandleToolsCall(const AId: TJSONValue; const AParams: TJSONObject);
    function  ReadRequest: string;
    procedure SendResponse(const AResponse: TMCPResponse);
    procedure SendError(const AId: TJSONValue; ACode: Integer; const AMessage: string);
    procedure ProcessRequest(const ALine: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterTool(const ATool: TMCPTool);
    procedure Run;
  end;

implementation

{ TMCServer }

constructor TMCServer.Create;
begin
  FTools := TDictionary<string, TMCPTool>.Create;
  FInitialized := False;
end;

destructor TMCServer.Destroy;
begin
  FTools.Free;
  inherited;
end;

procedure TMCServer.RegisterTool(const ATool: TMCPTool);
begin
  FTools.AddOrSetValue(ATool.Schema.Name, ATool);
end;

function TMCServer.ReadRequest: string;
begin
  Result := '';
  if not TTextReader.IsConsolePresent then
    Exit;
  ReadLn(Result);
end;

procedure TMCServer.SendResponse(const AResponse: TMCPResponse);
begin
  WriteLn(AResponse.ToJson);
  Flush(Output);
end;

procedure TMCServer.SendError(const AId: TJSONValue; ACode: Integer; const AMessage: string);
var
  LResp: TMCPResponse;
  LErr: TJSONObject;
begin
  LErr := TJSONObject.Create;
  LErr.AddPair('code', TJSONNumber.Create(ACode));
  LErr.AddPair('message', AMessage);
  LResp.Id := AId;
  LResp.Result := nil;
  LResp.Error := LErr;
  SendResponse(LResp);
  LErr.Free;
end;

procedure TMCServer.HandleInitialize(const AId: TJSONValue; const AParams: TJSONObject);
var
  LResp: TMCPResponse;
  LResult: TJSONObject;
begin
  FInitialized := True;
  LResult := TJSONObject.Create;
  LResult.AddPair('protocolVersion', '2024-11-05');
  var LCapabilities := TJSONObject.Create;
  var LTools := TJSONObject.Create;
  LTools.AddPair('listChanged', TJSONFalse.Create);
  LCapabilities.AddPair('tools', LTools);
  LResult.AddPair('capabilities', LCapabilities);
  LResult.AddPair('serverInfo', TJSONObject.Create
    .AddPair('name', 'MinusAI')
    .AddPair('version', '1.0.0'));
  LResp.Id := AId;
  LResp.Result := LResult;
  LResp.Error := nil;
  SendResponse(LResp);
  LResult.Free;
end;

procedure TMCServer.HandleToolsList(const AId: TJSONValue; const AParams: TJSONObject);
var
  LResp: TMCPResponse;
  LResult: TJSONObject;
  LArr: TJSONArray;
  LTool: TMCPTool;
begin
  LArr := TJSONArray.Create;
  for LTool in FTools.Values do
    LArr.AddElement(LTool.Schema.ToJson);
  LResult := TJSONObject.Create;
  LResult.AddPair('tools', LArr);
  LResp.Id := AId;
  LResp.Result := LResult;
  LResp.Error := nil;
  SendResponse(LResp);
  LResult.Free;
end;

procedure TMCServer.HandleToolsCall(const AId: TJSONValue; const AParams: TJSONObject);
var
  LName: string;
  LArgs: TJSONObject;
  LTool: TMCPTool;
  LToolResult: TMCPToolResult;
  LResp: TMCPResponse;
  LResultObj: TJSONObject;
begin
  LName := '';
  LArgs := nil;
  if AParams <> nil then
  begin
    if AParams.TryGetValue('name', LName) then
      LName := LName;
    if AParams.TryGetValue('arguments', LArgs) then
      LArgs := LArgs as TJSONObject;
  end;
  LArgs := AParams.GetValue('arguments') as TJSONObject;

  if not FTools.TryGetValue(LName, LTool) then
  begin
    SendError(AId, -32601, Format('Tool not found: %s', [LName]));
    Exit;
  end;

  LToolResult := LTool.Execute(LArgs);
  LResultObj := TJSONObject.Create;
  LResultObj.AddPair('content', LToolResult.Content);
  if LToolResult.IsError then
    LResultObj.AddPair('isError', TJSONTrue.Create);
  LResp.Id := AId;
  LResp.Result := LResultObj;
  LResp.Error := nil;
  SendResponse(LResp);
  LResultObj.Free;
end;

procedure TMCServer.ProcessRequest(const ALine: string);
var
  LObj: TJSONObject;
  LId: TJSONValue;
  LMethod: string;
  LParams: TJSONObject;
  LRequestId: string;
begin
  if ALine.Trim = '' then
    Exit;

  LObj := TJSONObject.ParseJSONValue(ALine) as TJSONObject;
  if LObj = nil then
  begin
    SendError(nil, -32700, 'Parse error');
    Exit;
  end;

  try
    if not LObj.TryGetValue('method', LMethod) then
    begin
      SendError(nil, -32600, 'Invalid Request: method required');
      Exit;
    end;

    LParams := nil;
    LObj.TryGetValue('params', LParams);
    LObj.TryGetValue('id', LId);

    if SameText(LMethod, 'initialize') then
      HandleInitialize(LId, LParams)
    else if SameText(LMethod, 'tools/list') then
      HandleToolsList(LId, LParams)
    else if SameText(LMethod, 'tools/call') then
      HandleToolsCall(LId, LParams)
    else if SameText(LMethod, 'notifications/initialized') then
      FInitialized := True
    else if SameText(LMethod, 'notifications/cancelled') then
      { no-op }
    else
      SendError(LId, -32601, Format('Method not found: %s', [LMethod]));
  finally
    LObj.Free;
  end;
end;

procedure TMCServer.Run;
var
  LLine: string;
begin
  while not EOF(Input) do
  begin
    LLine := ReadRequest;
    if LLine <> '' then
      ProcessRequest(LLine);
  end;
end;

end.
