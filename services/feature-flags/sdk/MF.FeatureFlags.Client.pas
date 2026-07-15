unit MF.FeatureFlags.Client;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.WebSocket,
  System.JSON,
  System.Generics.Collections,
  System.Hash;

type
  TFlagContext = record
    UserId: string;
    GroupId: string;
    Attributes: TDictionary<string, string>;
    constructor Create(const AUserId: string); overload;
    constructor Create(const AUserId, AGroupId: string); overload;
    procedure AddAttribute(const AKey, AValue: string);
    procedure FreeAttributes;
  end;

  TFlagEntry = class
  private
    FKey: string;
    FEnabled: Boolean;
    FVariant: string;
    FRolloutPercentage: Integer;
  public
    constructor Create(const AKey: string; AEnabled: Boolean;
      const AVariant: string; ARolloutPercentage: Integer);
    property Key: string read FKey;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Variant: string read FVariant write FVariant;
    property RolloutPercentage: Integer read FRolloutPercentage write FRolloutPercentage;
  end;

  TFeatureFlagEvent = procedure(const AFlagName: string; AEnabled: Boolean) of object;

  TReconnectThread = class(TThread)
  private
    FClient: TObject;
    FDelayMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AClient: TObject; ADelayMs: Integer);
  end;

  TFeatureFlags = class
  private
    FBaseURL: string;
    FAPIKey: string;
    FEnvironmentID: string;
    FHTTPClient: THTTPClient;
    FWebSocket: TWebSocketClient;
    FCache: TObjectDictionary<string, TFlagEntry>;
    FToken: string;
    FConnected: Boolean;
    FReconnectAttempt: Integer;
    FReconnectThread: TReconnectThread;
    FDestroying: Boolean;
    FOnFlagChanged: TFeatureFlagEvent;
    FOnConnected: TNotifyEvent;
    FOnDisconnected: TNotifyEvent;
    FOnError: TNotifyEvent;
    procedure RequestToken;
    procedure ConnectWebSocket;
    procedure OnWSConnected(ASender: TObject);
    procedure OnWSMessage(ASender: TObject; const AData: string);
    procedure OnWSError(ASender: TObject; const AError: string);
    procedure OnWSDisconnected(ASender: TObject);
    procedure HandleMessage(const AData: string);
    procedure HandleConnected(const AJSON: TJSONObject);
    procedure HandleFlagUpdated(const AJSON: TJSONObject);
    procedure HandleFlagDeleted(const AJSON: TJSONObject);
    procedure HandlePing;
    procedure ScheduleReconnect;
    procedure DoReconnect;
    function HashUser(const AUserId, AFlagName: string): Integer;
    function IsInRollout(const AUserId, AFlagName: string; ARolloutPercentage: Integer): Boolean;
    function WSURL: string;
    procedure DoOnFlagChanged(const AFlagName: string; AEnabled: Boolean);
    procedure DoOnConnected;
    procedure DoOnDisconnected;
    procedure DoOnError;
  public
    constructor Create(const ABaseURL, AAPIKey, AEnvironmentID: string);
    destructor Destroy; override;
    function IsEnabled(const AName: string; const AContext: TFlagContext): Boolean;
    function GetVariant(const AName: string; const AContext: TFlagContext): string;
    property OnFlagChanged: TFeatureFlagEvent read FOnFlagChanged write FOnFlagChanged;
    property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;
    property OnDisconnected: TNotifyEvent read FOnDisconnected write FOnDisconnected;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property Connected: Boolean read FConnected;
  end;

implementation

const
  CMaxReconnectDelay = 30000;

{ TFlagContext }

constructor TFlagContext.Create(const AUserId: string);
begin
  UserId := AUserId;
  GroupId := '';
  Attributes := TDictionary<string, string>.Create;
end;

constructor TFlagContext.Create(const AUserId, AGroupId: string);
begin
  UserId := AUserId;
  GroupId := AGroupId;
  Attributes := TDictionary<string, string>.Create;
end;

procedure TFlagContext.AddAttribute(const AKey, AValue: string);
begin
  Attributes.AddOrSetValue(AKey, AValue);
end;

procedure TFlagContext.FreeAttributes;
begin
  Attributes.Free;
  Attributes := nil;
end;

{ TFlagEntry }

constructor TFlagEntry.Create(const AKey: string; AEnabled: Boolean;
  const AVariant: string; ARolloutPercentage: Integer);
begin
  FKey := AKey;
  FEnabled := AEnabled;
  FVariant := AVariant;
  FRolloutPercentage := ARolloutPercentage;
end;

{ TReconnectThread }

constructor TReconnectThread.Create(AClient: TObject; ADelayMs: Integer);
begin
  FClient := AClient;
  FDelayMs := ADelayMs;
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TReconnectThread.Execute;
begin
  Sleep(FDelayMs);
  if not TThread.CheckTerminated then
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FClient) then
          (FClient as TFeatureFlags).DoReconnect;
      end);
end;

{ TFeatureFlags }

constructor TFeatureFlags.Create(const ABaseURL, AAPIKey, AEnvironmentID: string);
begin
  FBaseURL := ABaseURL.TrimRight(['/']);
  FAPIKey := AAPIKey;
  FEnvironmentID := AEnvironmentID;
  FDestroying := False;
  FConnected := False;
  FReconnectAttempt := 0;
  FToken := '';

  FHTTPClient := THTTPClient.Create;
  FHTTPClient.ConnectionTimeout := 10000;
  FHTTPClient.ResponseTimeout := 15000;

  FCache := TObjectDictionary<string, TFlagEntry>.Create([doOwnsValues]);

  RequestToken;
end;

destructor TFeatureFlags.Destroy;
begin
  FDestroying := True;

  if Assigned(FReconnectThread) then
  begin
    FReconnectThread.FClient := nil;
    FReconnectThread.Terminate;
    FReconnectThread := nil;
  end;

  if Assigned(FWebSocket) then
  begin
    FWebSocket.OnConnected := nil;
    FWebSocket.OnMessage := nil;
    FWebSocket.OnError := nil;
    FWebSocket.OnDisconnected := nil;
    if FConnected then
      FWebSocket.Disconnect;
    FWebSocket.Free;
    FWebSocket := nil;
  end;

  FHTTPClient.Free;
  FCache.Free;
  inherited;
end;

function TFeatureFlags.WSURL: string;
var
  LHost: string;
begin
  LHost := FBaseURL;
  if LHost.StartsWith('https://') then
    LHost := 'wss://' + LHost.Substring(8)
  else if LHost.StartsWith('http://') then
    LHost := 'ws://' + LHost.Substring(7);
  Result := LHost + '/ws?token=' + FToken;
  if FEnvironmentID <> '' then
    Result := Result + '&environment=' + FEnvironmentID;
end;

procedure TFeatureFlags.RequestToken;
var
  LResponse: IHTTPResponse;
  LJSON: TJSONObject;
  LToken: string;
begin
  try
    var LHeaders := TNetHeaders.Create(TNetHeader.Create('X-API-Key', FAPIKey));
    var LBody: TStringStream;
    if FEnvironmentID <> '' then
    begin
      var LReq := TJSONObject.Create;
      try
        LReq.AddPair('environment_id', FEnvironmentID);
        LBody := TStringStream.Create(LReq.ToJSON);
      finally
        LReq.Free;
      end;
    end
    else
      LBody := TStringStream.Create('{}');

    try
      LResponse := FHTTPClient.Post(FBaseURL + '/api/v1/ws/token',
        LBody, nil, LHeaders);
    finally
      LBody.Free;
    end;

    if LResponse.StatusCode <> 200 then
    begin
      ScheduleReconnect;
      Exit;
    end;

    LJSON := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
    if not Assigned(LJSON) then
    begin
      ScheduleReconnect;
      Exit;
    end;

    try
      if LJSON.TryGetValue<string>('token', LToken) then
      begin
        FToken := LToken;
        ConnectWebSocket;
      end
      else
        ScheduleReconnect;
    finally
      LJSON.Free;
    end;
  except
    ScheduleReconnect;
  end;
end;

procedure TFeatureFlags.ConnectWebSocket;
begin
  if FDestroying then
    Exit;

  if Assigned(FWebSocket) then
  begin
    FWebSocket.OnConnected := nil;
    FWebSocket.OnMessage := nil;
    FWebSocket.OnError := nil;
    FWebSocket.OnDisconnected := nil;
    FWebSocket.Free;
    FWebSocket := nil;
  end;

  FWebSocket := TWebSocketClient.Create;
  FWebSocket.OnConnected := OnWSConnected;
  FWebSocket.OnMessage := OnWSMessage;
  FWebSocket.OnError := OnWSError;
  FWebSocket.OnDisconnected := OnWSDisconnected;

  try
    FWebSocket.Connect(WSURL);
  except
    FWebSocket.Free;
    FWebSocket := nil;
    ScheduleReconnect;
  end;
end;

procedure TFeatureFlags.OnWSConnected(ASender: TObject);
begin
  FConnected := True;
  FReconnectAttempt := 0;
  TThread.Queue(nil, DoOnConnected);
end;

procedure TFeatureFlags.OnWSMessage(ASender: TObject; const AData: string);
begin
  HandleMessage(AData);
end;

procedure TFeatureFlags.OnWSError(ASender: TObject; const AError: string);
begin
  TThread.Queue(nil, DoOnError);
end;

procedure TFeatureFlags.OnWSDisconnected(ASender: TObject);
begin
  FConnected := False;
  TThread.Queue(nil, DoOnDisconnected);
  if not FDestroying then
    ScheduleReconnect;
end;

procedure TFeatureFlags.HandleMessage(const AData: string);
var
  LJSON: TJSONObject;
  LType: string;
begin
  LJSON := TJSONObject.ParseJSONValue(AData) as TJSONObject;
  if not Assigned(LJSON) then
    Exit;

  try
    if not LJSON.TryGetValue<string>('type', LType) then
      Exit;

    if LType = 'connected' then
      HandleConnected(LJSON)
    else if LType = 'flag_updated' then
      HandleFlagUpdated(LJSON)
    else if LType = 'flag_deleted' then
      HandleFlagDeleted(LJSON)
    else if LType = 'ping' then
      HandlePing;
  finally
    LJSON.Free;
  end;
end;

procedure TFeatureFlags.HandleConnected(const AJSON: TJSONObject);
var
  LFlags: TJSONArray;
  LObj: TJSONObject;
  I: Integer;
  LKey, LVariant: string;
  LEnabled: Boolean;
  LRolloutPercentage: Integer;
begin
  if not AJSON.TryGetValue<TJSONArray>('flags', LFlags) then
    Exit;

  FCache.Clear;
  for I := 0 to LFlags.Count - 1 do
  begin
    LObj := LFlags.Items[I] as TJSONObject;
    LKey := LObj.GetValue<string>('key');
    LEnabled := LObj.GetValue<Boolean>('enabled');

    if not LObj.TryGetValue<string>('variant', LVariant) then
      LVariant := '';
    if not LObj.TryGetValue<Integer>('rollout_percentage', LRolloutPercentage) then
      LRolloutPercentage := 100;

    FCache.AddOrSetValue(LKey, TFlagEntry.Create(LKey, LEnabled, LVariant, LRolloutPercentage));
  end;
end;

procedure TFeatureFlags.HandleFlagUpdated(const AJSON: TJSONObject);
var
  LKey, LVariant: string;
  LEnabled: Boolean;
  LRolloutPercentage: Integer;
begin
  LKey := AJSON.GetValue<string>('key');
  LEnabled := AJSON.GetValue<Boolean>('enabled');

  if not AJSON.TryGetValue<string>('variant', LVariant) then
    LVariant := '';
  if not AJSON.TryGetValue<Integer>('rollout_percentage', LRolloutPercentage) then
    LRolloutPercentage := 100;

  FCache.AddOrSetValue(LKey, TFlagEntry.Create(LKey, LEnabled, LVariant, LRolloutPercentage));
  DoOnFlagChanged(LKey, LEnabled);
end;

procedure TFeatureFlags.HandleFlagDeleted(const AJSON: TJSONObject);
var
  LKey: string;
begin
  LKey := AJSON.GetValue<string>('key');
  FCache.Remove(LKey);
  DoOnFlagChanged(LKey, False);
end;

procedure TFeatureFlags.HandlePing;
begin
  if Assigned(FWebSocket) and FConnected then
  begin
    try
      FWebSocket.Send('{"type":"pong"}');
    except
    end;
  end;
end;

procedure TFeatureFlags.ScheduleReconnect;
var
  LDelay: Integer;
begin
  if FDestroying then
    Exit;

  Inc(FReconnectAttempt);
  LDelay := 1000 * (1 shl (FReconnectAttempt - 1));
  if LDelay > CMaxReconnectDelay then
    LDelay := CMaxReconnectDelay;

  FReconnectThread := TReconnectThread.Create(Self, LDelay);
end;

procedure TFeatureFlags.DoReconnect;
begin
  FReconnectThread := nil;
  if FDestroying then
    Exit;

  if not FConnected then
    RequestToken;
end;

function TFeatureFlags.HashUser(const AUserId, AFlagName: string): Integer;
begin
  Result := Abs(THashBobJenkins.GetHashValue(AUserId + ':' + AFlagName)) mod 100;
end;

function TFeatureFlags.IsInRollout(const AUserId, AFlagName: string;
  ARolloutPercentage: Integer): Boolean;
begin
  if ARolloutPercentage >= 100 then
    Exit(True);
  if ARolloutPercentage <= 0 then
    Exit(False);
  if AUserId = '' then
    Exit(True);
  Result := HashUser(AUserId, AFlagName) < ARolloutPercentage;
end;

function TFeatureFlags.IsEnabled(const AName: string; const AContext: TFlagContext): Boolean;
var
  LEntry: TFlagEntry;
begin
  if not FCache.TryGetValue(AName, LEntry) then
    Exit(False);

  if not LEntry.Enabled then
    Exit(False);

  if LEntry.RolloutPercentage < 100 then
    Exit(IsInRollout(AContext.UserId, AName, LEntry.RolloutPercentage));

  Result := True;
end;

function TFeatureFlags.GetVariant(const AName: string; const AContext: TFlagContext): string;
var
  LEntry: TFlagEntry;
begin
  Result := 'control';
  if not FCache.TryGetValue(AName, LEntry) then
    Exit;

  if not LEntry.Enabled then
    Exit;

  if LEntry.Variant = '' then
    Exit;

  if LEntry.RolloutPercentage < 100 then
  begin
    if not IsInRollout(AContext.UserId, AName, LEntry.RolloutPercentage) then
      Exit('control');
  end;

  Result := LEntry.Variant;
end;

procedure TFeatureFlags.DoOnFlagChanged(const AFlagName: string; AEnabled: Boolean);
begin
  if Assigned(FOnFlagChanged) then
    FOnFlagChanged(AFlagName, AEnabled);
end;

procedure TFeatureFlags.DoOnConnected;
begin
  if Assigned(FOnConnected) then
    FOnConnected(Self);
end;

procedure TFeatureFlags.DoOnDisconnected;
begin
  if Assigned(FOnDisconnected) then
    FOnDisconnected(Self);
end;

procedure TFeatureFlags.DoOnError;
begin
  if Assigned(FOnError) then
    FOnError(Self);
end;

end.
