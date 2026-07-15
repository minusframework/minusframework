### Task 5: Delphi Cloud Exporter SDK

**Files:**
- Create: `services/telemetry/sdk/MF.Telemetry.Cloud.pas`

**Interfaces:**
- Consumes: `TBaseExporter` from existing `MF.Telemetry.Exporter.pas`
- Produces: `TCloudExporter` that sends spans/metrics to cloud API via HTTP

- [ ] **Step 1: Create sdk/MF.Telemetry.Cloud.pas**

```pascal
unit MF.Telemetry.Cloud;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.JSON,
  System.Generics.Collections,
  MF.Telemetry,
  MF.Telemetry.Exporter;

type
  TCloudExporter = class(TBaseExporter)
  private
    FBaseURL: string;
    FAPIKey: string;
    FHTTPClient: THTTPClient;
    FBuffer: TList<ISpan>;
    FLastFlush: TDateTime;
    FFlushIntervalSec: Integer;
    FMaxRetries: Integer;
    FCurrentRetry: Integer;
    procedure Flush;
    procedure InternalFlush(Buffer: TList<ISpan>);
    function GetConfigFromServer: Boolean;
  public
    constructor Create(const ABaseURL, AAPIKey: string);
    destructor Destroy; override;
    procedure ExportSpan(ASpan: ISpan); override;
    procedure ExportMetric(AMetric: IMetric); override;
    property FlushIntervalSec: Integer read FFlushIntervalSec write FFlushIntervalSec;
  end;

implementation

{ TCloudExporter }

constructor TCloudExporter.Create(const ABaseURL, AAPIKey: string);
begin
  inherited Create;
  FBaseURL := ABaseURL;
  FAPIKey := AAPIKey;
  FHTTPClient := THTTPClient.Create;
  FBuffer := TList<ISpan>.Create;
  FFlushIntervalSec := 60;
  FMaxRetries := 5;
  FCurrentRetry := 0;
  FLastFlush := Now;
  GetConfigFromServer;
end;

destructor TCloudExporter.Destroy;
begin
  if FBuffer.Count > 0 then
    Flush;
  FBuffer.Free;
  FHTTPClient.Free;
  inherited;
end;

procedure TCloudExporter.ExportSpan(ASpan: ISpan);
begin
  FBuffer.Add(ASpan);
  if (Now - FLastFlush) * 86400 >= FFlushIntervalSec then
    Flush;
end;

procedure TCloudExporter.ExportMetric(AMetric: IMetric);
var
  JSON: TJSONObject;
  Response: IHTTPResponse;
  URL: string;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('metric_name', AMetric.Name);
    JSON.AddPair('metric_type', AMetric.MetricType);
    JSON.AddPair('value', TJSONNumber.Create(AMetric.Value));
    JSON.AddPair('timestamp', DateToISO8601(Now));

    URL := FBaseURL + '/v1/metrics';
    Response := FHTTPClient.Post(URL, TStringStream.Create(JSON.ToJSON),
      TEncoding.UTF8, TNetHeaders.Create(TNetHeader.Create('X-API-Key', FAPIKey)));

    if Response.StatusCode <> 200 then
    begin
      if FCurrentRetry < FMaxRetries then
      begin
        Inc(FCurrentRetry);
        Sleep(1000 * (1 shl FCurrentRetry));
        ExportMetric(AMetric);
      end;
    end
    else
      FCurrentRetry := 0;
  finally
    JSON.Free;
  end;
end;

function TCloudExporter.GetConfigFromServer: Boolean;
var
  Response: IHTTPResponse;
  JSON: TJSONObject;
begin
  Result := False;
  try
    Response := FHTTPClient.Get(FBaseURL + '/api/v1/config');
    if Response.StatusCode = 200 then
    begin
      JSON := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONObject;
      try
        if Assigned(JSON) then
        begin
          if JSON.TryGetValue('flush_interval_seconds', FFlushIntervalSec) then
            Result := True;
        end;
      finally
        JSON.Free;
      end;
    end;
  except
    // Silently fail, use defaults
  end;
end;

procedure TCloudExporter.Flush;
var
  BufferCopy: TList<ISpan>;
begin
  if FBuffer.Count = 0 then Exit;
  BufferCopy := TList<ISpan>.Create;
  try
    BufferCopy.AddRange(FBuffer);
    FBuffer.Clear;
    InternalFlush(BufferCopy);
  finally
    BufferCopy.Free;
  end;
end;

procedure TCloudExporter.InternalFlush(Buffer: TList<ISpan>);
var
  JSON: TJSONObject;
  SpansJSON: TJSONArray;
  SpanJSON: TJSONObject;
  I: Integer;
  Response: IHTTPResponse;
  URL: string;
begin
  JSON := TJSONObject.Create;
  try
    SpansJSON := TJSONArray.Create;
    for I := 0 to Buffer.Count - 1 do
    begin
      SpanJSON := TJSONObject.Create;
      SpanJSON.AddPair('trace_id', Buffer[I].TraceID);
      SpanJSON.AddPair('span_id', Buffer[I].SpanID);
      SpanJSON.AddPair('operation_name', Buffer[I].OperationName);
      SpanJSON.AddPair('service_name', Buffer[I].ServiceName);
      SpanJSON.AddPair('span_kind', Buffer[I].SpanKind);
      SpanJSON.AddPair('start_time', DateToISO8601(Buffer[I].StartTime));
      SpanJSON.AddPair('end_time', DateToISO8601(Buffer[I].EndTime));
      SpanJSON.AddPair('status', Buffer[I].Status);
      SpansJSON.Add(SpanJSON);
    end;
    JSON.AddPair('trace_id', Buffer[0].TraceID);
    JSON.AddPair('spans', SpansJSON);

    URL := FBaseURL + '/v1/traces';
    Response := FHTTPClient.Post(URL, TStringStream.Create(JSON.ToJSON),
      TEncoding.UTF8, TNetHeaders.Create(TNetHeader.Create('X-API-Key', FAPIKey)));

    if Response.StatusCode <> 200 then
    begin
      if FCurrentRetry < FMaxRetries then
      begin
        Inc(FCurrentRetry);
        Sleep(1000 * (1 shl FCurrentRetry));
        InternalFlush(Buffer);
      end
      else
      begin
        // Drop oldest 25% when buffer full
        while Buffer.Count > 10000 do
          Buffer.Delete(0);
        FBuffer.AddRange(Buffer);
      end;
    end
    else
      FCurrentRetry := 0;
  finally
    JSON.Free;
  end;
end;

end.
```

- [ ] **Step 2: Commit**

```bash
git add services/telemetry/sdk/
git commit -m "feat: add TCloudExporter Delphi SDK for telemetry cloud ingestion"
```
