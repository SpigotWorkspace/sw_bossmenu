
<h1 align="center">[ESX] sw_bossmenu</h3>
Bossmenu for ESX jobs

### Features

- **Rank Management**: Promotion and demotion of players
- **Employee Management**: Hiring and firing of players
- **Account Management**: Deposits and withdrawals to the society account

### Requirements
- [esx_society](https://github.com/esx-framework/esx_society)
- [oxmysql](https://github.com/overextended/oxmysql)

### Installation
To ensure that withdrawals and deposits to the society account work correctly, changes must be made in the `esx_society/main.lua` file. Follow these steps: 
<br><h3>Change line 67</h3>
Replace the existing line:
```lua
if xPlayer.job.name ~= society.name then
    return print(('[^3WARNING^7] Player ^5%s^7 attempted to withdraw from society - ^5%s^7!'):format(source, society.name))
end
```
with:
```lua
local allowed = exports["sw_bossmenu"]:IsAllowed(xPlayer, 'withdrawMoney')
if xPlayer.job.name ~= society.name or not allowed then
    return print(('[^3WARNING^7] Player ^5%s^7 attempted to withdraw from society - ^5%s^7!'):format(source, society.name))
end
```

<br><h3>Change line 93</h3>
Replace the existing line:
```lua
if xPlayer.job.name ~= society.name then
    return print(('[^3WARNING^7] Player ^5%s^7 attempted to deposit to society - ^5%s^7!'):format(source, society.name))
end
```
with:
```lua
local allowed = exports["sw_bossmenu"]:IsAllowed(xPlayer, 'depositMoney')
if xPlayer.job.name ~= society.name or not allowed then
    return print(('[^3WARNING^7] Player ^5%s^7 attempted to deposit to society - ^5%s^7!'):format(source, society.name))
end
```

### Configuration
In the [adminconfig.lua](./adminconfig.lua) -> _Config.AllowedGrades_ you can configure which rank is allowed to do what for the respective job.<br>
In addition, individual persons can be given rights in the _Config.AllowedIdentifiers_ section per identifier.
For example, an admin can then manage the job without being the boss himself.

### Usage
#### Usage for users with grade configured in  _Config.AllowedGrades_
```lua
TriggerEvent('sw_bossmenu:openUI', '<jobname>')
```
Example:
```lua
TriggerEvent('sw_bossmenu:openUI', 'police')
```

#### Usage for users with identifier configured in  _Config.AllowedIdentifiers_
The jobs can then be managed with the command /bossmenu &lt;job&gt; if the respective rights are available.<br>
With e.g. /bossmenu police you then manage the police job

