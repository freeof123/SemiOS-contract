### SemiOS
#### Dependencies:
Foundry
#### Compile
forge b

//this will take some time to update dependencies, better to use proxy

#### Test
forge t

#### Deploy
ENV=main/test forge script ./script/Deploy.s.sol --private-key=$PRIVATE_KEY --rpc-url=<your_rpc_url> --broadcast  --verify

//requering the .env file with following environment variables

ETHERSCAN_API_KEY=64TEZETKNQM79UU5WB2S9U9HRMFISESCBX\
PRIVATE_KEY=<private-key-here>

//requiring the address file with following path
./deployed-contract-info/main-d4a.json     or\
./deployed-contract-info/test-d4a.json\
with following contents:\
{\
  "ProxyAdmin": "0x3f0ee71e17BDBf14B5ac0D97E459E44714740f3b",\
  "PDProtocol": {\
    "proxy": "0x63A647fca74D696457eB9a4378281756fbd7d071",\
    "impl": "0xbb9aC0954f2cDEe64888dB7c4fE755dED5384367",\
    "PDProtocolReadable": "0xe37bd549Bd68cAe78BaA4b7064C6932Af5aF931A",\
    "PDProtocolSetter": "0xb4dCC95C4Ef9beCb68Cc83c20c07faf088A3186F",\
    "PDCreate": "0x4Deb015a69174097635D289C63a3b180E951E80b",\
    "PDBasicDao": "0x16984d8D831B336cc4a380De0870BF1FDdDF4887",\
    "PDRound": "0xAd2b61B001FcDEc9E922E43cb6f92b55efEad01A",\
    "PDLock": "0x4E49B22E64D09b7A82e3261d6A3e1c0b07Ab4E94",\
    "PDGrant": "0xce4714A1B3198d78571763C03cccAa634F20da03",\
    "PDPlan": "0x69b862945ab8c0167f82A31c6d6C96618506348A",\
    "D4ASettings": "0x5b900B4304A300F5E7d1622149c1AcC0c2E440d9",\
    "LinearPriceVariation": "0xBb109380eC0Ea971eCa9a449Fe1025DD0bd931Cb",\
    "ExponentialPriceVariation": "0x1F585cDD05841E870CD3A437f0d4076A7457cA4f",\
    "UniformDistributionRewardIssuance": "0x27711F1cE67ddEeE8E31E7F90E8257C03551B320",\
    "DynamicPlan": "0xf2A862F017828487b52F2f439689aD3dC9AF2B09"\
  },\
  "PermissionControl": {
    "proxy": "0xB96Ab55CbA66834c92DD6d984F309a82a1c98b10",\
    "impl": "0x8f3C8420aC6bf36195970e361e0D2f0f17982855"\
  },\
  "NaiveOwner": {
    "proxy": "0xD39C2aE17f39C0961851995Bc10c3d687Ebd8e39",\
    "impl": "0x12c687cb10DF6D37A876C567d8656F513e12d6d1"\
  },\
  "factories": {\
    "D4AERC20Factory": "0x22FFdb2CC1393Ffc9b5b379dE8B62d8B3B315cA6",\
    "D4AERC721WithFilterFactory": "0xebFedbacdAe0BcA359Aa4c230a92D1AE7C3F8baD",\
    "D4AFeePoolFactory": "0x8C24A28Bd1eE6Da9adBd37efdE86d7201e4BbF51",\
    "D4ARoyaltySplitterFactory": "0xD9DE314a55Ff57099758557F869dF714732CA015"\
  },\
  "WETH": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",\
  "D4ASwapFactory": "0x40082EEdca51A13E2910bBaDc1A0F87ce5730668",\
  "UniswapV2Router": "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",\
  "OracleRegistry": "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",\
  "D4AUniversalClaimer": "0x5B212229F81eD324d197710c5cDD94dc9dbB817B",\
  "MultiSig1": "0x064D35db3f037149ed2c35c118a3bd79Fa4fE323"\
}

#### Generate abi and event/error selectors
