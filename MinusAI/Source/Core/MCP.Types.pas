unit MCP.Types;

interface

uses
  System.JSON, System.Generics.Collections;

type
  TMCPRequest = record
    JsonRpc: string;
    Id: TJSONValue;
    Method: string;
    Params: TJSONObject;
    function IsNotification: Boolean;
  end;

  TMCPToolSchema = record
    Name: string;
    Description: string;
    InputSchema: TJSONObject;
    function ToJson: TJSONObject;
  end;

  TMCPToolResult = record
    Content: TJSONArray;
    IsError: Boolean;
  end;

  TToolExecute = reference to function(const AParams: TJSONObject): TMCPToolResult;

  TMCPTool = record
    Schema: TMCPToolSchema;
    Execute: TToolExecute;
  end;

  TMCPResponse = record
    Id: TJSONValue;
    Result: TJSONValue;
    Error: TJSONObject;
    function ToJson: string;
  end;

  EMCPError = class(Exception);

implementation

{ TMCPRequest }

function TMCPRequest.IsNotification: Boolean;
begin
  Result := Id = nil;
end;

{ TMCPToolSchema }

function TMCPToolSchema.ToJson: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', Name);
  Result.AddPair('description', Description);
  if InputSchema <> nil then
    Result.AddPair('inputSchema', InputSchema.Clone as TJSONObject)
  else
    Result.AddPair('inputSchema', TJSONObject.Create);
end;

{ TMCPResponse }

function TMCPResponse.ToJson: string;
var
  LObj: TJSONObject;
begin
  LObj := TJSONObject.Create;
  LObj.AddPair('jsonrpc', '2.0');
  if Id <> nil then
    LObj.AddPair('id', Id.Clone as TJSONValue)
  else
    LObj.AddPair('id', TJSONNull.Create);
  if Error <> nil then
    LObj.AddPair('error', Error.Clone as TJSONObject)
  else if Result <> nil then
    LObj.AddPair('result', Result.Clone as TJSONValue);
  Result := LObj.ToJSON;
  LObj.Free;
end;

end.
