
### 在订阅文件的所有包含关键字的代理组中，添加指定节点

clash verge程序：订阅->全局扩展脚本(右键)->编辑文件
```js
function main(config, profileName) {

  // 你要添加的自定义节点（可以添加多个）
  const localNodes = [
    {
      name: "Local-SOCKS",
      type: "socks5",
      server: "10.67.0.110",
      port: 7890,
    }
  ];

  // 把自定义节点追加进 config.proxies
  if (!config.proxies) config.proxies = [];
  config.proxies.push(...localNodes);

  // 定义匹配关键字（可以自由扩展）
  const matchKeywords = ["切换", "选择"];

  // 遍历所有代理组，凡是名字包含上述关键字的，都追加节点
  if (config["proxy-groups"] && Array.isArray(config["proxy-groups"])) {
    config["proxy-groups"].forEach((group) => {
      if (
        matchKeywords.some((kw) => group.name.toLowerCase().includes(kw.toLowerCase()))
      ) {
        if (!group.proxies) group.proxies = [];
        // 插入到组的最前面
        localNodes
          .slice()
          .reverse()
          .forEach((node) => {
            if (!group.proxies.includes(node.name)) {
              group.proxies.unshift(node.name);
            }
          });
      }
    });
  }

  return config;
}

```
