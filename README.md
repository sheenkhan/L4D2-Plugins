**自用求生之路2纯净多特写专服务器**

## 食用说明

#### 安装依赖软件

```bash
sudo dpkg --add-architecture i386
sudo apt update && sudo apt install lib32gcc1 lib32stdc++6 libc6-i386 libcurl4-gnutls-dev:i386
sudo apt install screen git wget
```

#### 求生之路2服务端下载

```bash
cd ~
mkdir game && cd game
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar xf steamcmd_linux.tar.gz
./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 validate +quit
```

#### 安装插件

```bash
git clone https://github.com/fdxx/L4D2-Plugins
cp -r L4D2-Plugins/* ~/game/l4d2/
```

#### 配置修改

```bash
## 服务器名称修改
~/game/l4d2/left4dead2/addons/sourcemod/configs/hostname/hostname.txt

## 聊天框区域轮播广告修改
~/game/l4d2/left4dead2/addons/sourcemod/configs/advertisements.txt

## 管理员绑定
~/game/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini

## 特感数量和刷新时间修改
~/game/l4d2/left4dead2/cfg/sourcemod/l4dinfectedbots.cfg

## 其他配置修改
~/game/l4d2/left4dead2/cfg/server.cfg
~/game/l4d2/left4dead2/cfg/sourcemod/
```

也可以到`scripting/new`修改源码用`compile.sh`重新编译插件。

#### 启动服务器

```bash
chmod +x ~/game/l4d2/start.sh
~/game/l4d2/start.sh
```

后台运行：`Ctrl+A` 加 `Ctrl+D`

切回前台：`screen -r`

## 插件依赖

- [Sourcemod 1.10](https://www.sourcemod.net/downloads.php?branch=stable)
- [Metamod 1.11](https://www.sourcemm.net/downloads.php/?branch=stable)
- [L4DToolZ](https://forums.alliedmods.net/showpost.php?p=2720921&postcount=1445)
- [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?p=2684862)
- [DHooks](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
- [Tickrate-Enabler](https://github.com/Satanic-Spirit/Tickrate-Enabler)
- [l4d_info_editor](https://forums.alliedmods.net/showthread.php?t=310586)
- [Multi Colors](https://github.com/Bara/Multi-Colors)

## 插件说明

- **advertisements** 聊天框区域轮播广告插件，来源：[点击](https://github.com/ErikMinekus/sm-advertisements)
- **all4dead2** 管理员刷物品、特感插件，命令`!admin`，来源：[点击](https://github.com/fbef0102/L4D2-Plugins)
- **command_buffer** 缓冲区溢出修复，来源：[点击](https://forums.alliedmods.net/showthread.php?t=309656)
- **firebulletsfix** 修复子弹偏移 1 Tick 的问题，来源：[点击](https://github.com/fbef0102/L4D1_2-Plugins)
- **fix_fastmelee** 近战速砍修复，来源：[点击](https://forums.alliedmods.net/showthread.php?p=2407280)
- **hostname** 服务器中文名支持，来源：[点击](https://github.com/HMBSbige/SouceModPlugins)
- **l4d_afk_commands** 闲置、加入、自杀命令，命令`!away`、`!join`、`!zs`
- **l4d_gear_transfer** R键给物品、Bot自动给物品，来源：[点击](https://forums.alliedmods.net/showthread.php?t=137616)
- **l4d_god_frames** 无敌帧(起身、硬直)修复，来源：[点击](https://forums.alliedmods.net/showthread.php?t=320023)
- **l4d_skip_intro** 跳过首章地图的过场动画，来源：[点击](https://forums.alliedmods.net/showthread.php?t=321993)
- **l4d_votepoll_fix** 修复观众可以投票的问题，来源：[点击](https://forums.alliedmods.net/showthread.php?p=1974527)
- **l4d2_custom_commands** 新增管理员命令，命令`!admin`，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2704580&postcount=483)
- **l4d2_drop** 丢弃物品插件，命令`!drop`、`!g`，来源：[点击](https://forums.alliedmods.net/showthread.php?t=123098&page=9)
- **l4d2_kill_mvp** 击杀排名插件，命令`!mvp`，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2666056&postcount=9)
- **l4d2_melee_in_the_saferoom** 安全屋刷近战，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2719475&postcount=500)
- **l4d2_skill_detect**、**l4d2_stats** smoker tongue cut、skeet hunter 等骚操作提示，来源：[点击](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_skill_detect.sp)、[点击](https://github.com/TGMaster/Sourcepawn/blob/master/l4d2_stats.sp)
- **l4dinfectedbots** 多特插件，来源：[点击](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4dinfectedbots)
- **sm_RestartEmpty** 空服后重启服务器，来源：[点击](https://forums.alliedmods.net/showthread.php?t=315367)
- **logcommands** 客户端聊天、命令记录，来源：[点击](https://github.com/Franc1sco/Commands-Logger)
- **rygive** 另一个管理员刷物品、特感插件，命令`!rygive`，来源QQ群
- **SaferoomHPRestore** 开局回血，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2647749&postcount=8)
- **sm_l4d_mapchanger** 过关自动换图，来源：[点击](https://github.com/Raysamatoken/L4D2-Server-plugins/blob/master/left4dead2/addons/sourcemod/scripting/sm_l4d2_mapchanger.sp)
- **TickrateFixes** 高Tickrate修复，来源：[点击](https://github.com/SirPlease/L4D2-Competitive-Rework)
- **votes** 投票回血、踢人、换图插件，命令`!v`，来源：[点击](https://bbs.3dmgame.com/thread-2094823-1-1.html)
- **stripper** 在地图上添加或删除物品，用于在c1m1开局添加枪械，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2720408&postcount=1735)
- **Playerjoin** 玩家加入、离开提示，来源：[点击](https://forums.alliedmods.net/showthread.php?t=213471)
- **lerpmonitor** 跟踪、显示玩家lerp值，来源：[点击](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/lerpmonitor.sp)
- **sam_vs** 自动踢闲置玩家，来源：[点击](https://github.com/raziEiL/SourceMod/blob/master/released/sam_vs.sp)
- **UnreserveLobby** 移除大厅匹配，来源：[点击](https://github.com/deximy/PlusMod/blob/master/addons/sourcemod/scripting/UnreserveLobby.sp)
- **FollowTarget_Detour** 修复因切换团队导致的随机崩溃问题，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2725811&postcount=19)
- **l4d2_random_starting_map** 随机启动地图

## 其他说明

- 插件使用 Linux 安装，不支持 Windows
- 部分插件源码经过修改
- 注意插件依赖问题，直接取用单个插件不保证能用
- 有防火墙的注意放行`~/game/l4d2/start.sh`里面的启动端口

## 删除插件

```bash
chmod +x ~/game/l4d2/rm_plugin.sh
~/game/l4d2/rm_plugin.sh
```
