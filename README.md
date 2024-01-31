### ProtoDAO

1.  D4AERC721 为 721 的基类，D4AERC721WithFilter 继承了 D4AERC721，现在 PDERC721WithFilter 继承了 D4AERC721WithFilter，
    重写了 mintItem 和 initialize 方法，但是 721Factory 为 D4AERC721WithFilterFactory。

2.  创建 DAO 和 Canvas，ProtoDAO 有两个切面，分别为 `PDCreate` 和 `D4ACreate`，两个合约是代码复制粘贴的，无继承关系，因
    为代码逻辑改动的地方比较零散。

3.  在 Foundry 框架中，任何需要用到 `--rpc-url` 的地方，如果没有指定 `--rpc-url`，

        - 如果设置了 `ETH_RPC_URL` 的环境变量 ，则会优先使用该变量作为 `rpc url`,

        - 否则会使用 `localhost:8545` 端口

    如果指定了 `--rpc-url`，则优先使用指定的 `url`。

4.  调用 `createCanvasAndMintNFT` 接口时，参数 to 地址为 canvas creator，由于调用者可以任意指定 to 地址，但如果对应的，
    不将 signature 也改变的话，在 mint NFT 时，会导致 signature 还原出来的 signer 和 canvas creator 不一致，导致交易
    revert，如果调用者将 to 地址和 signature 同时改变，使得 signature 为指定的 to 地址的私钥对正确参数签名后得到的
    signature，则交易可以正常执行，同时修改了 canvas 的 creator。但是这种攻击风险不考虑。


---

git clone

yarn install

forge b

forge t