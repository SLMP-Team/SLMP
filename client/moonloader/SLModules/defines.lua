PACKET =
{
  CONFIRM_RECEIVING = 1,
  CONNECTION_REQUEST = 2,
  CONNECTION_REQUEST_FAIL = 3,
  CONNECTION_REQUEST_SUCCESS = 4,
  UPDATE_STREAM = 5,
  ONFOOT_SYNC = 6,
  PING_SERVER = 7,
  DISCONNECT_NOTIFICATION = 8
}

RPC =
{
  PLAYER_CONNECT = 1,
  PLAYER_DISCONNECT = 2,
  UPDATE_PING_AND_SCORE = 3,
  SET_PLAYER_SKIN = 4,
  SET_PLAYER_POS = 5,
  SET_PLAYER_INTERIOR = 6,
  SET_PLAYER_ANGLE = 7,
  SEND_MESSAGE = 8,
  SEND_COMMAND = 9
}

GAMESTATE =
{
  DISCONNECTED = 1,
  CONNECTING = 2,
  CONNECTED = 3
}

PLAYERSTATE =
{
  ONFOOT = 1
}

ffi.cdef[[
int __stdcall GetVolumeInformationA(
  const char* lpRootPathName,
  char* lpVolumeNameBuffer,
  uint32_t nVolumeNameSize,
  uint32_t* lpVolumeSerialNumber,
  uint32_t* lpMaximumComponentLength,
  uint32_t* lpFileSystemFlags,
  char* lpFileSystemNameBuffer,
  uint32_t nFileSystemNameSize
);
]]
sVolumeToken = ffi.new("unsigned long[1]", 0)
ffi.C.GetVolumeInformationA(nil, nil, 0, sVolumeToken, nil, nil, nil, 0)