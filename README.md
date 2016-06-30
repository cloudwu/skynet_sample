这是一个使用 skynet 搭建服务器的简单例子。它很简陋，主要想演示一下 https://github.com/cloudwu/skynet_package 以及 sproto 协议封装的用法。

这个例子可以作为构建游戏服务器的参考，但它并不作为 skynet 推荐的服务器框架使用模式。它还很不完整，可能存在许多疏忽的地方，以及需要针对实际需求做进一步优化。

如何编译
========

1. clone 下本仓库。
2. 更新 submodule ，服务器部分需要用到 skynet ；客户端部分需要用到 lsocket 。
```
git submodule update --init
```
3. 编译 skynet
```
cd skynet
make linux
```
4. 编译 lsocket（如果你需要客户端）
```
make socket
```
5. 编译 skynet package 模块
```
make
```

如何运行服务器
==============

以前台模式启动
```
./run.sh
```
用 Ctrl-C 可以退出

以后台模式启动
```
./run.sh -D
```

用下列指令可以杀掉后台进程
```
./run.sh -k
```

后台模式下，log 记录在 `run/skynet.log` 中。

如何运行客户端
==============

客户端启动脚本为 `client/simpleclient.lua` ，它依赖 sproto 和 lsocket 两个模块。

ps. sproto 和 lsocket 均可在 mingw 下编译。

客户端需要 Lua 5.3 以上，在 skynet/3rd/lua 下有 lua 5.3.3 解析器。

客户端脚本启动需要传入两个参数，第一个参数是根目录的位置，以方便找到依赖的模块和协议文件 `proto/proto.sproto` ；第二个参数是服务器地址，默认为 127.0.0.1 。

`./client.sh` 这个脚本可以简化客户端启动流程。

服务器工作流程
==============

1. hub 服务监听 5678 端口，当有新连接接入时，启动一个 `skynet_package` 服务，管理这个链接。

2. hub 服务把这个新连接交给 auth 服务管理。

3. auth 服务接受客户端的 signup 和 signin 请求。signup 可以注册一个用户名；signin 可以以一个已注册用户名登录。这里只做简单演示，并没有认证用户的身份。

4. 当 signin 成功后，hub 服务把链接转交给 manager 服务。

5. manager 服务将查找是否有 agent 服务对应这个用户；如果没有，则启动一个新的 agent 并记录 agent 服务和用户名之间的关系。

6. manager 服务通知 agent 接管这个连接，并将此连接关联到特定用户名下。

7. agent 服务会接收客户端的 login 请求。如果用户已在线（有其它连接已关联）通知客户端 login 失败；否则成功，且可以接收 ping 等其它请求。

8. 当连接主动断开时，agent 将等待 10 秒，如果这段时间没有重建连接，将在 manager 中注销并自行销毁。

客户端工作流程
==============

客户端以请求回应模式和服务器交流，不能接收服务器的任何主动推送。

1. 客户端启动时，将尝试连接服务器，并提出 signin 请求。

2. 如果 signin 失败，将尝试 signup 注册一个用户，如果再失败则退出。成功则重新 singin 。

3. 如果 signin 成功，将向服务器请求 login ；在 login 之前，会向服务器发起 ping 请求，但一定会失败。

4. login 成功后，向服务器发起 ping 。



