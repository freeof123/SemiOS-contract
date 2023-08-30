### ProtoDAO

1.  D4AERC721 为 721 的基类，D4AERC721WithFilter 继承了 D4AERC721，现在 PDERC721WithFilter 继承了 D4AERC721WithFilter，
    重写了 mintItem 和 initialize 方法，但是 721Factory 为 D4AERC721WithFilterFactory。

2.  创建 DAO 和 Canvas，ProtoDAO 有两个切面，分别为 `PDCreate` 和 `D4ACreate`，两个合约是代码复制粘贴的，无继承关系，因
    为代码逻辑改动的地方比较零散。

3.  在 Foundry 框架中，任何需要用到 `--rpc-url` 的地方，如果没有指定 `--rpc-url`，

        - 如果设置了 `ETH_RPC_URL` 的环境变量 ，则会优先使用该变量作为 `rpc url`,

        - 否则会使用 `localhost:8545` 端口

    如果指定了 `--rpc-url`，则优先使用指定的 `url`。
