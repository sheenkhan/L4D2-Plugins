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
~/game/l4d2/left4dead2/cfg/sourcemod/l4d2_infectedbots_fix_ch.cfg

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

- [Sourcemod 1.10](https://www.sourcemod.net/downloads.php?branch=1.10-dev)
- [Metamod 1.10](https://www.sourcemm.net/downloads.php?branch=1.10-dev)
- [L4DToolZ](https://forums.alliedmods.net/showpost.php?p=1984946&postcount=1210)
- [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?p=2684862)
- [DHooks](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
- [Tickrate-Enabler](https://github.com/Satanic-Spirit/Tickrate-Enabler)
- [l4d_info_editor](https://forums.alliedmods.net/showthread.php?t=310586)

## 插件说明

- **all4dead2** 管理员刷物品、特感插件，命令`!admin`，来源：[点击](https://github.com/fbef0102/L4D2-Plugins)
- **command_buffer** 缓冲区溢出修复，来源：[点击](https://forums.alliedmods.net/showthread.php?t=309656)
- **fix_fastmelee** 近战速砍修复，来源：[点击](https://forums.alliedmods.net/showthread.php?p=2407280)
- **hostname** 服务器中文名支持，来源：[点击](https://github.com/HMBSbige/SouceModPlugins)
- **l4d_gear_transfer** R键给物品、Bot自动给物品，来源：[点击](https://forums.alliedmods.net/showthread.php?t=137616)
- **l4d_god_frames** 无敌帧(起身、硬直)修复，来源：[点击](https://forums.alliedmods.net/showthread.php?t=320023)
- **l4d_skip_intro** 跳过首章地图的过场动画，来源：[点击](https://forums.alliedmods.net/showthread.php?t=321993)
- **l4d2_abbw_msgrs** 自杀插件，命令`!zs`，来源QQ群
- **l4d2_custom_commands** 新增管理员命令，命令`!admin`，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2704580&postcount=483)
- **l4dinfectedbots** 多特插件，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2663190&postcount=1360)
- **l4d2_melee_in_the_saferoom** 安全屋刷近战，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2719073&postcount=494)
- **linux_auto_restart** 空服后重启服务器，来源：[点击](https://github.com/fbef0102/L4D1_2-Plugins)
- **rygive** 另一个管理员刷物品、特感插件，命令`!rygive`，来源QQ群
- **sm_l4d_mapchanger** 过关自动换图，来源QQ群
- **l4d2_kill_mvp** 击杀排名插件，命令`!mvp`，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2666056&postcount=9)
- **TickrateFixes** 高Tickrate修复，来源：[点击](https://github.com/SirPlease/L4D2-Competitive-Rework)
- **votes** 投票回血、踢人、换图插件，命令`!v`，来源：[点击](https://bbs.3dmgame.com/thread-2094823-1-1.html)
- **l4d2_msg_system_zh** 各种类型消息提示，来源QQ群
- **l4d_afk_commands** 闲置、加入命令，命令`!away`、`!join`，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2718427&postcount=30)
- **advertisements** 聊天框区域轮播广告插件，来源：[点击](https://github.com/ErikMinekus/sm-advertisements)
- **l4d_votepoll_fix** 修复观众可以投票的问题，来源：[点击](https://forums.alliedmods.net/showthread.php?p=1974527)
- **survivor_afk_fix** AFK命令修复，来源：[点击](https://forums.alliedmods.net/showthread.php?p=2714236)
- **firebulletsfix** 修复子弹偏移 1 Tick 的问题，来源：[点击](https://github.com/fbef0102/L4D1_2-Plugins)
- **SaferoomHPRestore** 开局回血，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2647749&postcount=8)
- **stripper** 在地图上添加或删除物品，用于在c1m1开局添加枪械，来源：[点击](https://forums.alliedmods.net/showpost.php?p=2720408&postcount=1735)
- **l4d2_disable_afk** 禁用`go_away_from_keyboard`命令，来源：[点击](https://forums.alliedmods.net/showthread.php?p=2711822)
- **logcommands** 客户端聊天、命令记录，来源：[点击](https://github.com/Franc1sco/Commands-Logger)

## 其他说明

- 插件使用 Debian 安装，不支持 Windows
- 部分插件源码经过修改，直接取用单个插件不保证能用
- 有防火墙的注意放行`~/game/l4d2/start.sh`里面的启动端口

## 删除插件

```bash
chmod +x ~/game/l4d2/rm_plugin.sh
~/game/l4d2/rm_plugin.sh
```
