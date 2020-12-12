#To enable these settings, name this file "user_settings.py".
import os, re, sys

default_user_settings = {
    #By default, logs are saved to $HOME/steam-<STEAM_GAME_ID>.log, overwriting any previous log with that name.
    #Log directory can be overridden with $PROTON_LOG_DIR.

    #Wine debug logging
    #https://wiki.winehq.org/Wine_Developer%27s_Guide/Debug_Logging
   "WINEDEBUG": "+timestamp,+pid,+tid,+seh,+debugstr,+loaddll,+mscoree,fixme-all",
    #"WINEDEBUG": "fixme-all,trace-all,warn+all,err+all,message+all,warn-winsock,warn-fsync",

    #DXVK debug logging
    "DXVK_LOG_LEVEL": "warn",

    #vkd3d debug logging
    "VKD3D_DEBUG": "warn",

    #wine-mono debug logging (Wine's .NET replacement)
    "WINE_MONO_TRACE": "E:System.NotImplementedException",
    #"MONO_LOG_LEVEL": "info",

    #general purpose media logging
#    "GST_DEBUG": "4",
    #or, verbose converter logging (may impact playback performance):
#    "GST_DEBUG": "4,protonaudioconverter:6,protonaudioconverterbin:6,protonvideoconverter:6",

    #Enable DXVK's HUD
#    "DXVK_HUD": "devinfo,fps",

    #Use OpenGL-based wined3d for d3d11, d3d10, and d3d9 instead of Vulkan-based DXVK
#    "PROTON_USE_WINED3D": "1",

    #Disable d3d11 entirely
#    "PROTON_NO_D3D11": "1",

    #Disable eventfd-based in-process synchronization primitives
#    "PROTON_NO_ESYNC": "1",

    #Disable futex-based in-process synchronization primitives
#    "PROTON_NO_FSYNC": "1",
}

# https://github.com/simons-public/protonfixes/blob/master/protonfixes/fix.py
def get_game_id():
  """ Trys to return the game id from environment variables
  """
  if 'SteamAppId' in os.environ:
      return os.environ['SteamAppId']
  if 'SteamGameId' in os.environ:
      return os.environ['SteamGameId']
  if 'STEAM_COMPAT_DATA_PATH' in os.environ:
      return re.findall(r'\d+', os.environ['STEAM_COMPAT_DATA_PATH'])[-1]
  raise Exception("cannot find game id")

user_settings = {}
def main():
  global user_settings 
  game_id = get_game_id()
  user_settings = default_user_settings

main()
